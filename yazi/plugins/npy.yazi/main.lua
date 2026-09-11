--- Preview `.npy` / `.npz` arrays.
---
--- The work happens in `preview.py` next to this file; we only page its output.
--- Set `YAZI_NPY_PYTHON` to use a different interpreter than `python3`.

local M = {}

local function msg(job, s)
	ya.preview_widget(job, ui.Text(ui.Line(s):reverse()):area(job.area):wrap(ui.Wrap.YES))
end

local function script()
	local base = os.getenv("YAZI_CONFIG_HOME")
	if not base or base == "" then
		local xdg = os.getenv("XDG_CONFIG_HOME")
		if not xdg or xdg == "" then
			xdg = (os.getenv("HOME") or "") .. "/.config"
		end
		base = xdg .. "/yazi"
	end
	return base .. "/plugins/npy.yazi/preview.py"
end

function M:peek(job)
	local python = os.getenv("YAZI_NPY_PYTHON")
	if not python or python == "" then
		python = "python3"
	end

	local child = Command(python)
		:arg({ script(), tostring(job.file.path), "--width", tostring(job.area.w) })
		:stdout(Command.PIPED)
		:stderr(Command.PIPED)
		:spawn()
	if not child then
		return msg(job, "npy preview: cannot run `" .. python .. "`")
	end

	local opt = { ansi = true, tab_size = rt.preview.tab_size, wrap = rt.preview.wrap, width = job.area.w }
	local limit = job.area.h
	local i, lines, errs = 0, {}, {}
	repeat
		local next, event = child:read_line()
		if event == 1 then
			errs[#errs + 1] = next:gsub("\r?\n$", "")
		elseif event ~= 0 then
			break
		else
			local wrapped = ui.lines(next, opt)
			local from = math.max(1, job.skip - i + 1)
			local to = math.min(#wrapped, job.skip + limit - i)
			i = i + #wrapped
			for j = from, to do
				lines[#lines + 1] = wrapped[j]
			end
		end
	until i >= job.skip + limit
	child:start_kill()

	if #lines == 0 and #errs > 0 then
		msg(job, errs[#errs])
	elseif job.skip > 0 and i < job.skip + limit then
		ya.emit("peek", { math.max(0, i - limit), only_if = job.file.url, upper_bound = true })
	else
		ya.preview_widget(job, ui.Text(lines):area(job.area))
	end
end

function M:seek(job) require("code"):seek(job) end

return M
