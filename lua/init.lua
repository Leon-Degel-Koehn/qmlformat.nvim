local M = {}
local actions = require('telescope.actions')
local actions_state = require('telescope.actions.state')
local finders = require('telescope.finders')
local pickers = require('telescope.pickers')
local previewers = require('telescope.previewers')
local plenary = require('plenary')
local utils = require('telescope.previewers.utils')
local bufnr

local function add_keymaps_to_buffer(curr_bufnr)
	vim.api.nvim_buf_create_user_command(curr_bufnr, "W", function()
		local curr_buff = vim.api.nvim_win_get_buf(0)
		local diff = vim.api.nvim_buf_get_lines(curr_buff, 0, -1, true)
		local filepath = vim.api.nvim_buf_get_name(bufnr)
		local lines = M._apply_patch(diff, filepath)
		vim.api.nvim_buf_set_lines(bufnr, 0, -1, true, lines)
	end, {})
end

local function edit_diff(diff)
	local diff_bufnr = vim.api.nvim_create_buf(false, true)
	local width = 500
	local height = 500
	local row = (vim.api.nvim_win_get_height(0) - height) / 2
	local col = (vim.api.nvim_win_get_width(0) - width) / 2
	local title = "Edit formatting diff"
	local current_window = vim.api.nvim_open_win(diff_bufnr, true, {
		style = "minimal",
		relative = "editor",
		width = width,
		height = height,
		row = row,
		col = col,
		border = "single",
		title = title
	})
	vim.wo[current_window].winhighlight = "Normal:Normal"
	vim.api.nvim_buf_set_lines(diff_bufnr, 0, -1, true, diff)
	utils.highlighter(diff_bufnr, 'qml')
	add_keymaps_to_buffer(diff_bufnr)
end

M._apply_patch = function(diff, filename)
	local patch_file = io.open(".qmlformat_patch", "w")
	patch_file:write(table.concat(diff, "\n"))
	patch_file:close()
	local result
	local job_opts = {
		command = 'patch',
		args = vim.tbl_flatten {'-o', '-', filename, ".qmlformat_patch"},
		on_exit = function(j, _)
			result = j:result()
		end,
	}
	plenary.job:new(job_opts):sync()
	os.remove(".qmlformat_formatted")
	return result
end

local _get_qmlformat_results = function(filepath)
	local original
	local formatted
	local diff
	local job_opts = {
		command = 'cat',
		args = vim.tbl_flatten {filepath},
		on_exit = function(j, _)
			original = j:result()
		end,
	}
	plenary.job:new(job_opts):sync()

	job_opts = {
		command = 'qmlformat',
		args = vim.tbl_flatten {'--normalize', filepath},
		on_exit = function(j, _)
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
		on_exit = function(j, _)
			diff = j:result()
			for linenum = 1, #diff do
				local line = diff[linenum]
				line = line:gsub(".qmlformat_original", filepath)
				line = line:gsub(".qmlformat_formatted", filepath)
				diff[linenum] = line
			end
		end,
	}
	plenary.job:new(job_opts):sync()
	os.remove(".qmlformat_formatted")
	os.remove(".qmlformat_original")
	return {original, formatted, diff}
end

M.preview_qmlformat_changes = function(opts)
	local filepath = vim.api.nvim_buf_get_name(0)
	bufnr = vim.api.nvim_get_current_buf()
	local preview_buffer
	local original = nil
	local formatted = nil
	local diff = nil
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
				local call
				if original == nil or formatted == nil or diff == nil then
					call = _get_qmlformat_results(filepath)
				else
					call = {original, formatted, diff}
				end
				vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, call[entry.index])
				preview_buffer = self.state.bufnr
				utils.highlighter(self.state.bufnr, 'qml')
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
				if selection.value == "diff" then
					edit_diff(content)
				end
			end)
			return true
		end,
	})
	:find()
end

vim.keymap.set('n', '<leader>q', M.preview_qmlformat_changes, {})

return M
