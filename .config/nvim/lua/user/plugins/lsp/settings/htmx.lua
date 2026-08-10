return {
	-- htmx-lsp provides completion for hx-* attributes. Extend beyond the
	-- default `html` filetype so it also fires in Go templates and eRuby.
	filetypes = { "html", "templ", "gohtml", "gohtmltmpl", "eruby" },
}
