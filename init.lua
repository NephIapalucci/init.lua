-- =========================================================================================================================================================
-- init.lua ---------- init.lua ---------- init.lua ---------- init.lua ---------- init.lua ---------- init.lua ---------- init.lua ---------- init.lua ----
-- =========================================================================================================================================================

--[[

Neph Iapalucci's init.lua configuration for Neovim.

-- ]]
-- =====================================================================================================================================================================
-- Options ---------- Options ---------- Options ---------- Options ---------- Options ---------- Options ---------- Options ---------- Options ---------- Options -----
-- =====================================================================================================================================================================

vim.opt.cursorline = true -- Highlight line that cursor is on
vim.opt.hlsearch = false -- Don't highlight searches
vim.opt.incsearch = true -- Incrementally highlight searches
vim.opt.mouse = nil -- Disable mouse
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Make line numbers relative to cursor position
vim.opt.wrap = false -- Disable word wrapping
vim.opt.tabstop = 4 -- Set tab size to 4
vim.opt.shiftwidth = 4 -- Use tabstop for automatic tabs
vim.opt.showcmd = false -- Don't show keypressed
vim.opt.termguicolors = true -- Use true color in the terminal
vim.cmd[[set fillchars=vert:\ ]] -- Remove line between file tree and main buffer

-- Enable word wrapping for text files such as markdown or text
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text" },
	callback = function()
		vim.opt_local.wrap = true
	end
})

vim.g.zig_fmt_autosave = false -- Disable Zig autoformatting which for some reason converts my enums into massive one-liners
vim.g.rustfmt_autosave = true -- Enable Rust formatting on save

vim.g.mapleader = " " -- Set leader to space

-- =========================================================================================================================================================
-- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- P
-- =========================================================================================================================================================

-- Bootstrapping: Automatically install Lazy.nvim if it doesn't exist
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath
	})
end
vim.opt.rtp:prepend(lazypath)

-- Start the plugin setup
require("lazy").setup({

	-- File tree explorer
	{
		"nvim-neo-tree/neo-tree.nvim",
		branch = "v2.x",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-tree/nvim-web-devicons",
			"MunifTanjim/nui.nvim"
		},
		config = function()
			require("neo-tree").setup({
				close_if_last_window = true,
				enable_diagnostics = true,
				window = {
					position = "left",
					width = 35
				},
				default_component_configs = {
					name = {
						use_git_status_colors = false
					},
					icon = {
						folder_empty = "",
						folder_empty_open = ""
					},
					modified = {
						symbol = "ﱣ "
					}
				}
			})

			vim.api.nvim_create_autocmd("VimEnter", {
				callback = function(args)
					if vim.fn.expand("%:p") ~= "" then
						vim.api.nvim_del_autocmd(args.id)
						vim.cmd("Neotree")
						vim.schedule(function()
							vim.cmd("wincmd p")
						end)
					end
				end
			})
		end
	},

	-- Add missing LSP diagnostic colors
	{
		'folke/lsp-colors.nvim',
		config = function()
			require("lsp-colors").setup({
				Error = "#db4b4b",
				Warning = "#e0af68",
				Information = "#0db9d7",
				Hint = "#10B981"
			})

		end
	},

	-- Pretty bottom status bar
	{
		'nvim-lualine/lualine.nvim',
		dependencies = { 'nvim-tree/nvim-web-devicons' },
		config = function()
			require("lualine").setup({
				extensions = { "neo-tree" },
				sections = {

					-- Set mode name to Camelcase
					lualine_a = {
						{
							'mode',
							fmt = function(str)
								return str:sub(1,1) .. str:sub(2, str:len()):lower()
							end
						}
					},

					-- Set the "B" section to be the file type
					lualine_b = {
						{
							'filetype',
							fmt = function(type)
								local formatted = type:sub(1, 1):upper() .. type:sub(2, type:len())
								if formatted == "Cs" then formatted = "C#" end
								return formatted
							end
						}
					},
					lualine_c = {}, -- Remove file name (present in tabline)
					lualine_x = {}, -- Remove file encoding

					-- Set "Y" section to diagnostics
					lualine_y = {
						{
							'diagnostics',
							symbols = {
								warn = "  ",
								error = " ",
								hint = " ",
								info = "  "
							},
						}
					},

					-- Set the "Z" section to be the line count
					lualine_z = {
						{
							'location',
							fmt = function()
								return vim.fn.line("$") .. " Lines"
							end
						}
					}
				}
			})
		end
	},

	-- Language Server support for diagnostics, autocomplete, etc.
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v2.x",
		build = function()
			vim.schedule(function()
				vim.cmd(":MasonUpdate")
			end)
		end,
		dependencies = {
			"simrat39/rust-tools.nvim", -- Rust LSP tools
			"rust-lang/rust.vim", -- Up-to-date Rust support
			"williamboman/mason.nvim", -- LSP Installer
			"williamboman/mason-lspconfig", -- LSP Configurer
			"hrsh7th/cmp-nvim-lsp", -- Autocomplete
			"hrsh7th/nvim-cmp", -- More auto complete
			"neovim/nvim-lspconfig", -- LSP Configuration
			"hrsh7th/cmp-cmdline", -- Command line completion
			"hrsh7th/cmp-buffer" -- Buffer integration into CMD completion

		},
		config = function()
			require("mason").setup({
				ui = {
					icons = {
						package_installed = "✓",
						package_pending = "",
						package_uninstalled = ""
					}
				}
			})

			require("mason-lspconfig").setup({
				ensure_installed = {
					"bashls", -- Bash
					"clangd", -- C
					"csharp_ls", -- C#
					"html", -- HTML
					"pyright", -- Python
					'rust_analyzer', -- Rust
					'tsserver', -- TypeScript
					'lua_ls', -- Lua
					'zls' -- Zig
				},
			})

			local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
			local lsp_attach = function() end -- Mappings

			local lspconfig = require('lspconfig')

			require('mason-lspconfig').setup_handlers({
				function(server_name)
					lspconfig[server_name].setup({
						on_attach = lsp_attach,
						capabilities = lsp_capabilities,
					})
				end,
			})

			-- Set up Rust format on save with clippy
			lspconfig.rust_analyzer.setup({
				settings = {
					['rust-analyzer'] = {
						checkOnSave = {
							allFeatures = true,
							overrideCommand = {
								"cargo", "clippy",
									"--workspace",
									"--message-format=json",
									"--all-targets",
									"--all-features"
							}
						}
					}
				}
			})

			-- Set up Lua to ignore vim as a global
			lspconfig.lua_ls.setup({
				settings = {
					Lua = {
						diagnostics = {
							globals = { "vim" }
						}
					}
				}
			})

			local cmp = require("cmp")

			-- Set up autocomplete for Vim commands
			cmp.setup.cmdline(":", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = cmp.config.sources({
					{ name = "path" }
				},
				{
					{
						name = "cmdline",
						option = {
							ignore_cmds = { "Man", "!" }
						}
					}
				})
			})

			-- Set up autocomplete for Vim finding
			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" }
				}
			})

			-- Set up autocomplete for files 
			cmp.setup({
				window = {
					completion = {
						border = "rounded"
					}
				}
			})

			local zero = require("lsp-zero").preset({})

			-- Set gutter icons
			zero.set_sign_icons({
				error = "",
				warn = "",
				hint = "",
				info = ""
			})
			zero.on_attach(function(_, bufnr)
				zero.default_keymaps({ buffer = bufnr })
			end)
			zero.setup()
		end
	},

	-- One Dark theme syntax highlighting
	{
		'NephIapalucci/onedarker-pro.nvim',
		config = function()
			local onedark = require("onedark")
			onedark.load()
		end,
		priority = 1000
	},

	-- Language parser for better semantic highlighting
	{
		'nvim-treesitter/nvim-treesitter',
		build = function()
			vim.schedule(function()
				vim.cmd(':TSUpdate')
			end)
		end,
		config = function()
			require('nvim-treesitter.configs').setup({
				ensure_installed = {
					"bash",
					"c",
					"go",
					"lua",
					"rust",
					"java",
					"javascript",
					"typescript",
					"racket",
					"zig",
					"markdown",
					"python"
				},
				sync_install = false,
				highlight = {
					enable = true,
				}
			})
		end
	},

	-- Show diagnostics on their own lines that point at the source character
	{
		"https://git.sr.ht/~whynothugo/lsp_lines.nvim",
		config = function()
			vim.diagnostic.config({
				virtual_text = false,
			})
			require("lsp_lines").setup()
			vim.cmd[[
			hi LspDiagnosticsVirtualTextWarning guifg=#e2b86b
			hi DiagnosticVirtualTextWarn guifg=#e2b86b 

			hi LspDiagnosticsVirtualTextError guifg=#e55561 ctermfg=15
			hi DiagnosticVirtualTextError guifg=#e55561 ctermfg=15
			]]
		end,
	},

	-- Top tabline to show open buffers
	{
		'kdheepak/tabline.nvim',
		config = function()
			require'tabline'.setup {
				-- Defaults configuration options
				enable = true,
				options = {
					show_tabs_always = true, -- this shows tabs only when there are more than one tab or if the first tab is named
					show_devicons = true, -- this shows devicons in buffer section
					show_bufnr = false, -- this appends [bufnr] to buffer section,
					show_filename_only = true, -- shows base filename only instead of relative path in filename
					modified_italic = false, -- set to true by default; this determines whether the filename turns italic if modified
				}
			}
			vim.cmd[[
			set guioptions-=e " Use showtabline in gui vim
			set sessionoptions+=tabpages,globals " store tabpages and globals in session
			]]
		end,
		dependencies = {
			{ 'nvim-lualine/lualine.nvim' },
			{ 'nvim-tree/nvim-web-devicons' }
		}
	},

	-- Icon picker for writing icons such as      etc
	{
		"ziontee113/icon-picker.nvim",
		dependencies = {
			"stevearc/dressing.nvim" ,
			"nvim-telescope/telescope.nvim"
		},
		config = function()
			require("icon-picker").setup({
				disable_legacy_commands = true
			})
		end
	},

	-- Highlight colors in the editor such as #4a08a9, rgb(0, 255, 255), and hsl(150, 100, 50)
	{
		"brenoprata10/nvim-highlight-colors",
		config = function()
			require("nvim-highlight-colors").setup({})
		end
	},

	-- Run projects
	{
		dir = '~/Documents/Coding/Lua/run.nvim',
		config = function()
			require("run").setup()
		end
	},

	-- Live markdown preview
	{
		"iamcco/markdown-preview.nvim",
		config = function()
			vim.schedule(function()
				vim.fn["mkdp#util#install"]()
			end)
		end
	},

	-- Command line improvements and message tooltips
	{
		"folke/noice.nvim",
		dependencies = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
			"rcarriga/nvim-notify"
		},
		config = function()

			-- Send notifications to the bottom of the screen instead of the top
			require("notify").setup({
				top_down = false
			})

			require("noice").setup({
				lsp = {
					override = {
						["vim.lsp.util.convert_input_to_markdown_lines"] = true,
						["vim.lsp.util.stylize_markdown"] = true,
						["cmp.entry.get_documentation"] = true
					}
				},
				cmdline = {
					view = "cmdline" -- Keep Vim commands to standard bottom CMDLine instead of middle of screen
				},
				presets = {
					bottom_search = true,
					long_message_to_split = true,
					inc_rename =  false,
					lsp_doc_border = true
				},
			})
		end
	},

	-- Highlight comments with  TODO: in them such as this, as well as FIXME and others
	{
		"folke/todo-comments.nvim",
		dependencies = "nvim-lua/plenary.nvim",
		config = function()
			require("todo-comments").setup({})
		end
	},

	-- Better UI for find and replace
	{
		"VonHeikemen/searchbox.nvim",
		dependencies = {
			{ "MunifTanjim/nui.nvim" }
		}
	}
},

-- Options for lazy.nvim
{
	ui = {
		colorscheme = { "onedark" },
		title = " Lazy ",
		border = "rounded",
		icons = {
			start = ""
		}
	}
})

-- ====================================================================================================================================
-- Mappings ---------- Mappings ---------- Mappings ---------- Mappings ---------- Mappings ---------- Mappings ---------- Mappings ---
-- ====================================================================================================================================

vim.keymap.set("n", "<leader><Tab>", ":bn<CR>", {}) -- Switch between open buffers
vim.keymap.set("n", "<leader>l", ":Lazy<CR>", {})
vim.keymap.set("n", "<leader>w", ":bd<CR>", {}) -- Closes the current buffer
vim.keymap.set("n", "<leader>s", ":w<CR>", {}) -- Saves the current buffer
vim.keymap.set("n", "<leader>r", ":NvimRun<CR>", {}) -- Runs the current project
vim.keymap.set("n", "<leader>m", ":IconPickerNormal<CR>", {}) -- Picks icons and glyphs
vim.keymap.set("n", "<leader>ef", ":Neotree<CR>", {}) -- Focus file tree
vim.keymap.set("n", "<leader>et", ":NvimTreeToggle<CR>", {}) -- Toggle file tree
vim.keymap.set("n", "<leader>eu", ":wincmd p<CR>", {}) -- Unfocus file tree
vim.keymap.set("n", "<leader>f", ":SearchBoxIncSearch<CR>", {}) -- Search within file

-- Lsp Mappings
vim.keymap.set("n", "<leader>ld", vim.lsp.buf.definition, {}) -- Jump to definition
vim.keymap.set("n", "<leader>ly", vim.lsp.buf.code_action, {}) -- Code Actions
vim.keymap.set("n", "<leader>lr", vim.lsp.buf.rename, {}) -- Rename refactoring
