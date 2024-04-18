local M = {}
local actions = require('telescope.actions')
local actions_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local plenary = require('plenary')

local _get_qmlformat_results = function(filepath)
	local original
	local formatted
	local diff
	local job_opts = {
		command = 'cat',
		args = vim.tbl_flatten {filepath},
		on_exit = function(j, return_val)
			original = j:result()
		end,
	}
	plenary.job:new(job_opts):sync()

	job_opts = {
		command = 'qmlformat',
		args = vim.tbl_flatten {'--normalize', filepath},
		on_exit = function(j, return_val)
			formatted = j:result()
		end,
	}
	plenary.job:new(job_opts):sync()

	-- I would love to pipe the strings from lua to the diff tool
	-- However, this didn't seem to work for me, so here we go
	local original_file = io.open(".qmlformat_original", "w")
	original_file:write(table.concat(original, "\n"))
	original_file:close()
	local formatted_file = io.open(".qmlformat_formatted", "w")
	formatted_file:write(table.concat(formatted, "\n"))
	formatted_file:close()

	job_opts = {
		command = 'diff',
		args = vim.tbl_flatten {
			'.qmlformat_original',
			'.qmlformat_formatted',
			'-u',
		},
		on_exit = function(j, return_val)
			diff = j:result()
		end,
	}
	plenary.job:new(job_opts):sync()
	os.remove(".qmlformat_formatted")
	os.remove(".qmlformat_original")
	return {original, formatted, diff}
end

M.preview_qmlformat_changes = function(opts)
	local filepath = vim.api.nvim_buf_get_name(0)
	local bufnr = vim.api.nvim_get_current_buf()
	local preview_buffer
	pickers
	.new(opts, {
		finder = finders.new_table {
			results = {
				'original',
				'formatted',
				'diff'
			},
			entry_maker = function(entry)
				-- TODO: check what we really need here, works for now
				return {
					value = entry,
					display = entry,
					ordinal = entry,
				}
			end
		},
		previewer = previewers.new_buffer_previewer({
			define_preview = function(self, entry)
				local call = _get_qmlformat_results(filepath)
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, call[entry.index])
				preview_buffer = self.state.bufnr
			end
		}),
		attach_mappings = function(prompt_bufnr)
			actions.select_default:replace(function()
				local selection = actions_state.get_selected_entry(prompt_bufnr)
				-- TODO: check if it is possible to access the preview bufnr in a different way
				local content = vim.api.nvim_buf_get_lines(preview_buffer, 0, -1, true)
				if selection.value == "formatted" or selection.value == "original" then
					vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, content)
					actions.close(prompt_bufnr)
				end
				-- TODO: define action for selection of the diff entry
				-- one idea is to open a new window where the user can edit the diff
				-- after finishing editing the user can choose to apply the diff to the file
			end)
			return true
		end,
	})
	:find()
end

vim.keymap.set('n', '<leader>q', M.preview_qmlformat_changes, {})

return M
