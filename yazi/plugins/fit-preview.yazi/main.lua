--- Size image / PDF previews to the preview pane instead of their pixel size.
---
--- Images: upscaled so they take at least half the pane width (still bounded by
--- the pane height). The conversion itself is left to the built-in previewer
--- named by `--base=` (default `image`).
---
--- PDFs: each page is rendered at the full pane width. A page taller than the
--- pane is shown in pane-sized slices; J/K (`seek`) scroll through the slices
--- and on to the next/previous page.
---
--- Needs `pdfinfo`/`pdftoppm` (poppler), ImageMagick, and `python3` (to read the
--- terminal cell size from the tty). Without a cell size, images are shown as
--- is and PDF pages are fitted to the pane.

local M = {}

-- `skip` for PDFs is page * PAGE + slice; slice PAGE - 1 means "last slice".
local PAGE = 1000
-- Fraction of the pane height kept from the previous slice when scrolling.
local OVERLAP = 0.1

local CELL_SIZE_PY = [[
import fcntl, os, struct, termios
fd = os.open("/dev/tty", os.O_RDONLY)
r, c, x, y = struct.unpack("HHHH", fcntl.ioctl(fd, termios.TIOCGWINSZ, bytes(8)))
print(x // c if c else 0, y // r if r else 0)
]]

local function cell_size()
	local out = Command("python3"):arg({ "-c", CELL_SIZE_PY }):stderr(Command.NULL):output()
	local w, h = (out and out.stdout or ""):match("(%d+) (%d+)")
	w, h = tonumber(w), tonumber(h)
	if w and h and w > 0 and h > 0 then
		return w, h
	end
end

local function show(job, url, start)
	ya.sleep(math.max(0, rt.preview.image_delay / 1000 + start - os.clock()))
	local _, err = ya.image_show(url, job.area)
	ya.preview_widget(job, err)
end

local function is_pdf(job)
	return job.mime == "application/pdf" or job.file.name:lower():match("%.pdf$") ~= nil
end

-- Images ---------------------------------------------------------------------

local function resize(src, dst, w, h)
	local size = string.format("%dx%d!", w, h)
	local op = rt.preview.image_filter == "nearest" and "-sample" or "-resize"
	local args = { tostring(src) .. "[0]", op, size, "PNG:" .. tostring(dst) }
	local status = Command("magick"):arg(args):status()
	if not status then
		status = Command("convert"):arg(args):status()
	end
	return status and status.success
end

function M:peek_image(job)
	local start, base = os.clock(), require(job.args.base or "image")
	local ok, err = base:preload(job)
	if not ok or err then
		return ya.preview_widget(job, err)
	end

	local cache = ya.file_cache(job)
	if not cache or not fs.cha(cache) then
		return base:peek(job)
	end

	local src, info, cw, ch = cache, ya.image_info(cache), cell_size()
	if info and cw then
		local min_w = math.floor(job.area.w / 2) * cw
		local scale = math.min(
			min_w / info.w,
			job.area.h * ch / info.h,
			rt.preview.max_width / info.w,
			rt.preview.max_height / info.h
		)
		if scale > 1 then
			local w, h = math.floor(info.w * scale), math.floor(info.h * scale)
			local up = Url(string.format("%s-%dx%d", tostring(cache), w, h))
			if fs.cha(up) or resize(cache, up, w, h) then
				src = up
			end
		end
	end
	show(job, src, start)
end

-- PDFs -----------------------------------------------------------------------

-- Page count and the page's size in points (after rotation).
local function pdf_page_info(path, page)
	local out = Command("pdfinfo"):arg({ "-f", page, "-l", page, tostring(path) }):output()
	if not out or not out.status.success then
		return
	end
	local s = out.stdout
	local pages = tonumber(s:match("Pages:%s+(%d+)"))
	local w, h = s:match("Page%s+%d+ size:%s+([%d.]+) x ([%d.]+)")
	local rot = tonumber(s:match("Page%s+%d+ rot:%s+(%d+)")) or 0
	w, h = tonumber(w), tonumber(h)
	if rot % 180 == 90 then
		w, h = h, w
	end
	return pages, w, h
end

function M:peek_pdf(job)
	local start, cache = os.clock(), ya.file_cache(job)
	if not cache then
		return
	end

	local page, slice = job.skip // PAGE, job.skip % PAGE
	local pages, pw, ph = pdf_page_info(job.file.path, page + 1)
	if not pages then
		return ya.preview_widget(job, Err("Failed to read PDF with `pdfinfo`"))
	elseif page >= pages then
		return ya.emit("peek", { (pages - 1) * PAGE + PAGE - 1, only_if = job.file.url, upper_bound = true })
	end

	-- Without a cell size, render the whole page and let yazi fit it to the pane.
	local cw, ch = cell_size()
	local w = cw and job.area.w * cw or rt.preview.max_width
	local h = math.ceil(w * ph / pw)
	local view_h = ch and job.area.h * ch or h
	local step = math.max(1, math.floor(view_h * (1 - OVERLAP)))
	local slices = h <= view_h and 1 or 1 + math.ceil((h - view_h) / step)
	if slice >= slices then
		local next_page = slice < PAGE - 1 and page + 1 < pages
		local skip = next_page and (page + 1) * PAGE or page * PAGE + slices - 1
		return ya.emit("peek", { skip, only_if = job.file.url, upper_bound = not next_page })
	end

	local y = math.min(slice * step, math.max(0, h - view_h))
	local out = string.format("%s-%dx%d", tostring(cache), w, view_h)
	local img = Url(out .. ".jpg")
	if not fs.cha(img) then
		-- stylua: ignore
		local output, err = Command("pdftoppm")
			:arg({
				"-f", page + 1, "-l", page + 1, "-singlefile",
				"-scale-to-x", w, "-scale-to-y", h,
				"-x", 0, "-y", y, "-W", w, "-H", math.min(view_h, h),
				"-jpeg", "-jpegopt", "quality=" .. rt.preview.image_quality,
				tostring(job.file.path), out,
			})
			:output()
		if not output then
			return ya.preview_widget(job, Err("Failed to start `pdftoppm`, error: %s", err))
		elseif not output.status.success then
			return ya.preview_widget(job, Err("Failed to convert PDF to image, stderr: %s", output.stderr))
		end
	end
	show(job, img, start)
end

function M:seek_pdf(job)
	local h = cx.active.current.hovered
	if not h or h.url ~= job.file.url then
		return
	end
	local skip = cx.active.preview.skip
	local step = ya.clamp(-1, job.units, 1)
	if step < 0 and skip % PAGE == 0 then
		-- Into the last slice of the previous page.
		skip = skip >= PAGE and skip - 1 or 0
	else
		skip = math.max(0, skip + step)
	end
	ya.emit("peek", { skip, only_if = job.file.url })
end

-- Entry points ---------------------------------------------------------------

function M:peek(job)
	if is_pdf(job) then
		return self:peek_pdf(job)
	end
	return self:peek_image(job)
end

function M:seek(job)
	if is_pdf(job) then
		return self:seek_pdf(job)
	end
end

-- PDF pages are rendered at peek time (the size depends on the pane), so skip
-- the built-in preloader's work.
function M:preload(job)
	if is_pdf(job) then
		return true
	end
	return require(job.args.base or "image"):preload(job)
end

function M:spot(job) require(is_pdf(job) and "file" or job.args.base or "image"):spot(job) end

return M
