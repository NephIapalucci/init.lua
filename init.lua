-- =========================================================================================================================================================
-- init.lua ---------- init.lua ---------- init.lua ---------- init.lua ---------- init.lua ---------- init.lua ---------- init.lua ---------- init.lua ----
-- =========================================================================================================================================================

--[[

Neph Iapalucci's init.lua configuration for Neovim.

-- ]]

-- =========================================================================================================================================================
-- Options ---------- Options ---------- Options ---------- Options ---------- Options ---------- Options ---------- Options ---------- Options ---------- O
-- =========================================================================================================================================================

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

-- Enable word wrapping for text files
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "markdown", "text" },
	callback = function()
		vim.opt_local.wrap = true
	end
})

-- =========================================================================================================================================================
-- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- P
-- =========================================================================================================================================================

-- Bootstrapping: Automatically install Packer if it doesn't exist
local packer_bootstrap = (function()
	local install_path = vim.fn.stdpath('data')..'/site/pack/packer/start/packer.nvim'
	if vim.fn.empty(vim.fn.glob(install_path)) > 0 then
		vim.fn.system({ 'git', 'clone', '--depth', '1', 'https://github.com/wbthomason/packer.nvim', install_path })
		vim.cmd [[packadd packer.nvim]]
		return true end
	return false
end)()

require("packer").startup(function(use)

	-- Package manager
	use 'wbthomason/packer.nvim'

	-- File tree
	use {
		'nvim-tree/nvim-tree.lua',
		requires = { 'nvim-tree/nvim-web-devicons' },
		config = function()
			-- Start the file tree with default settings
			require("nvim-tree").setup({
				update_focused_file = {
					enable = true
				},

				git = {
					enable = false,
					ignore = true
				}
			})

			-- Automatically open file tree when starting Neovim
			vim.api.nvim_create_autocmd("VimEnter", {callback = function()
				vim.cmd("NvimTreeToggle")
				vim.cmd("wincmd p")
			end})

			-- Automatically close when file tree is the last buffer remaining
			vim.api.nvim_create_autocmd("BufEnter", {
				command = "if winnr('$') == 1 && bufname() == 'NvimTree_' . tabpagenr() | quit | endif",
				nested = true
			})
		end
	}

	-- Add missing LSP diagnostic colors
	use {
		'folke/lsp-colors.nvim',
		config = function()
			require("lsp-colors").setup({
				Error = "#db4b4b",
				Warning = "#e0af68",
				Information = "#0db9d7",
				Hint = "#10B981"
			})

		end
	}

	-- Pretty bottom status bar
	use {
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
	}

	-- Language Server support for diagnostics
	use {
		"VonHeikemen/lsp-zero.nvim",
		branch = "v2.x",
		run = ":MasonUpdate",
		requires = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/nvim-cmp",
			"neovim/nvim-lspconfig"
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

			local zero = require("lsp-zero").preset({})
			zero.nvim_workspace() -- Fix Undefined global 'vim'

			-- Set gutter icons
			zero.set_sign_icons({
				error = "",
				warn = "",
				hint = "",
				info = ""
			})
			zero.on_attach(function(_client, bufnr)
				zero.default_keymaps({buffer = bufnr})
			end)
			zero.setup()
		end
	}

	-- One Dark theme highlighting
	use {
		'navarasu/onedark.nvim',
		config = function()
			local onedark = require("onedark")
			onedark.setup({
				style = 'darker', -- Set the style to darker

				-- Remove italic comments
				code_style = {
					comments = 'none',
				},
			})
			onedark.load()
		end
	}

	-- Language parser for better semantic highlighting
	use {
		'nvim-treesitter/nvim-treesitter',
		run = ':TSUpdate',
		config = function()
			require('nvim-treesitter.configs').setup({
				ensure_installed = { "c", "lua", "rust", "javascript", "typescript", "racket", "zig", "markdown" },
				sync_install = false,
				highlight = {
					enable = true,
				}
			})
		end
	}

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
	use {
		'nvim-telescope/telescope.nvim', tag = '0.1.1',
		requires = { {'nvim-lua/plenary.nvim'} },
		config = function() require("telescope").setup({}) end
	}

	-- Command mode completion in a popup menu
	use {
		'gelguy/wilder.nvim',
		config = function()
			local wilder = require("wilder")
			wilder.setup({modes =  {':', '/', '?'} })
			wilder.set_option('renderer', wilder.popupmenu_renderer(
			wilder.popupmenu_border_theme({
				highlights = {
					border = "none"
				},
				border = "rounded",
				left = {' ', wilder.popupmenu_devicons() },
				right = {' ', wilder.popupmenu_scrollbar() },
				highlighter = wilder.basic_highlighter()
			})
			))
		end
	}

	-- Top tabline to show buffers
	use {
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
	}

	-- Nerd icon picker for writing text
	use {
		"ziontee113/icon-picker.nvim",
		requires = { "stevearc/dressing.nvim" },
		config = function()
			require("icon-picker").setup({
				disable_legacy_commands = true
			})
		end
	}

	-- Highlight hex colors in the editor
	use {
		"brenoprata10/nvim-highlight-colors",
		config = function()
			require("nvim-highlight-colors").setup({})
		end
	}

	-- Finish bootstrapping
	if packer_bootstrap then
		require('packer').sync()
	end

end)

-- ====================================================================================================================================
-- Mappings ---------- Mappings ---------- Mappings ---------- Mappings ---------- Mappings ---------- Mappings ---------- Mappings ---
-- ====================================================================================================================================

vim.api.nvim_set_keymap("n", "<Tab>", ":bn<CR>", {}) -- Tab switches between open buffers
vim.api.nvim_set_keymap("n", "<C-w>", ":bd<CR>", {}) -- Ctrl + w closes the current buffer
vim.api.nvim_set_keymap("n", "<C-s>", ":w<CR>", {}) -- Ctrl + s saves the current buffer

