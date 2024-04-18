local M = {}
local actions = require('telescope.actions')
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
			 end
		 }),
		 attach_mappings = function(prompt_bufnr)
			 actions.select_default:replace(function()
				 actions.close(prompt_bufnr)
			 end)
			 return true
		 end,
	 })
	 :find()
end

vim.keymap.set('n', '<leader>q', M.preview_qmlformat_changes, {})

return M
