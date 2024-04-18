local M = {}
local pickers = require('telescope.pickers')
local finders = require('telescope.finders')
local previewers = require('telescope.previewers')
local config = require('telescope.config').values
local log = require('plenary.log'):new()
local plenary = require('plenary')
log.level = "debug"

M.preview_qmlformat_changes = function(opts)
	filepath = vim.api.nvim_buf_get_name(0)
	pickers.new(opts, {
		finder = finders.new_dynamic({
			fn = function()
				--return {"qmlformat", filepath}
				log.info("target:", filepath)
				local job_opts = {
					command = "qmlformat",
					args = vim.tbl_flatten {filepath},
				}
				log.info('Running job', job_opts)
				local job = plenary.job:new(job_opts):sync()
				log.info('Ran job', job)
				return job
			end,

			entry_maker = function(entry)
				return {
					value = entry,
					display = entry,
					ordinal = entry
				}
			end,
		}),

		sorter = config.generic_sorter(opts)
		
	}):find()
end

M.preview_qmlformat_changes()

return M
