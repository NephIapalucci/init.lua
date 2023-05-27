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

-- Enable word wrapping for text files
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text" },
	callback = function()
		vim.opt_local.wrap = true
	end
})

vim.g.zig_fmt_autosave = false -- Disable Zig autoformatting which for some reason converts my enums into massive one-liners

-- =========================================================================================================================================================
-- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- P
-- =========================================================================================================================================================

-- Bootstrapping: Automatically install Packer if it doesn't exist
local packer_bootstrap = (function()
	local install_path = vim.fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
	if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
		vim.fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
		vim.cmd [[packadd packer.nvim]]
		return true
	end
	return false
end)()

-- Start the plugin setup
require("packer").startup(function(use)

	-- Package manager
	use({'wbthomason/packer.nvim'})

	-- File tree
	use({
		'nvim-tree/nvim-tree.lua',
		requires = { 'nvim-tree/nvim-web-devicons' },
		config = function()
			-- Start the file tree with default settings
			require("nvim-tree").setup({
				update_focused_file = {
					enable = true
				},

				-- Disable git integration
				git = {
					enable = false,
					ignore = true
				}
			})

			-- Automatically close when file tree is the last buffer remaining
			vim.api.nvim_create_autocmd("BufEnter", {
				command = "if winnr('$') == 1 && bufname() == 'NvimTree_' . tabpagenr() | quit | endif",
				nested = true
			})
		end
	})

	-- Add missing LSP diagnostic colors
	use({
		'folke/lsp-colors.nvim',
		config = function()
			require("lsp-colors").setup({
				Error = "#db4b4b",
				Warning = "#e0af68",
				Information = "#0db9d7",
				Hint = "#10B981"
			})

		end
	})

	-- Pretty bottom status bar
	use({
		'nvim-lualine/lualine.nvim',
		requires = { 'nvim-tree/nvim-web-devicons' },
		config = function()
			require("lualine").setup({
				options = {
					disabled_filetypes = { 'NvimTree' }
				},
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
								return type:sub(1, 1):upper() .. type:sub(2, type:len())
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
							}
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
	})

	-- Language Server support for diagnostics
	use({
		"VonHeikemen/lsp-zero.nvim",
		branch = "v2.x",
		run = ":MasonUpdate",
		requires = {
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
					"clangd",
					"pyright",
					'rust_analyzer',
					'tsserver',
					'lua_ls',
					'zls'
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

			local cmp = require("cmp")

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

			cmp.setup.cmdline("/", {
				mapping = cmp.mapping.preset.cmdline(),
				sources = {
					{ name = "buffer" }
				}
			})


			cmp.setup({
				window = {
					completion = {
						border = "rounded"
					}
				}
			})

			local zero = require("lsp-zero").preset({})
			zero.nvim_workspace() -- Fix Undefined global 'vim'

			-- Set gutter icons
			zero.set_sign_icons({
				error = "",
				warn = "",
				hint = "",
				info = ""
			})
			zero.on_attach(function(_, bufnr)
				zero.default_keymaps({buffer = bufnr})
			end)
			zero.setup()
		end
	})

	-- One Dark theme highlighting
	use({
		'NephIapalucci/onedarker-pro.nvim',
		config = function()
			local onedark = require("onedark")
			onedark.load()
		end
	})

	-- Language parser for better semantic highlighting
	use({
		'nvim-treesitter/nvim-treesitter',
		run = ':TSUpdate',
		config = function()
			require('nvim-treesitter.configs').setup({
				ensure_installed = {
					"c",
					"lua",
					"rust",
					"java",
					"javascript",
					"typescript",
					"racket",
					"zig",
					"markdown"
				},
				sync_install = false,
				highlight = {
					enable = true,
				}
			})
		end
	})

	-- Show diagnostics on their own lines that point at the source character
	use({
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
	})

	-- Fuzzy finder
	use({
		'nvim-telescope/telescope.nvim', tag = '0.1.1',
		requires = { {'nvim-lua/plenary.nvim'} },
		config = function() require("telescope").setup({}) end
	})

	-- Top tabline to show buffers
	use({
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
		requires = {
			{ 'hoob3rt/lualine.nvim', opt = true },
			{ 'kyazdani42/nvim-web-devicons', opt = true }
		}
	})

	-- Nerd icon picker for writing text
	use({
		"ziontee113/icon-picker.nvim",
		requires = { "stevearc/dressing.nvim" },
		config = function()
			require("icon-picker").setup({
				disable_legacy_commands = true
			})
		end
	})

	-- Highlight hex colors in the editor
	use({
		"brenoprata10/nvim-highlight-colors",
		config = function()
			require("nvim-highlight-colors").setup({})
		end
	})

	-- Run projects
	use({
		'~/Documents/Coding/Lua/run.nvim',
		config = function()
			require("run").setup()
		end
	})

	-- Live markdown preview
	use({
		"iamcco/markdown-preview.nvim",
		run = function()
			vim.fn["mkdp#util#install"]()
		end
	})

	-- Command line improvements and message tooltips
	use({
		"folke/noice.nvim",
		requires = {
			"MunifTanjim/nui.nvim",
			"rcarriga/nvim-notify",
			"rcarriga/nvim-notify"
		},
		config = function()
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
					view = "cmdline"
				},
				presets = {
					bottom_search = true,
					long_message_to_split = true,
					inc_rename =  false,
					lsp_doc_border = true
				},
			})
		end
	})

	-- Highlight comments with TODO
	use({
		"folke/todo-comments.nvim",
		requires = "nvim-lua/plenary.nvim",
		config = function()
			require("todo-comments").setup({})
		end
	})

	-- Finish bootstrapping
	if packer_bootstrap then
		require('packer').sync()
	end

end)

-- ====================================================================================================================================
-- Mappings ---------- Mappings ---------- Mappings ---------- Mappings ---------- Mappings ---------- Mappings ---------- Mappings ---
-- ====================================================================================================================================

vim.g.mapleader = " " -- Set leader to space
vim.keymap.set("n", "<leader><Tab>", ":bn<CR>", {}) -- Switch between open buffers
vim.keymap.set("n", "<leader>w", ":bd<CR>", {}) -- Closes the current buffer
vim.keymap.set("n", "<leader>s", ":w<CR>", {}) -- Saves the current buffer
vim.keymap.set("n", "<leader>r", ":NvimRun<CR>", {}) -- Runs the current project
vim.keymap.set("n", "<leader>y", ":IconPickerNormal<CR>", {}) -- Picks icons and glyphs
vim.keymap.set("n", "<leader>ef", ":NvimTreeFocus<CR>", {}) -- Focus file tree
vim.keymap.set("n", "<leader>et", ":NvimTreeToggle<CR>", {}) -- Toggle file tree
vim.keymap.set("n", "<leader>eu", ":wincmd p<CR>", {}) -- Unfocus file tree
vim.keymap.set("n", "<leader>ff", require("telescope.builtin").find_files, {}) -- Find files
