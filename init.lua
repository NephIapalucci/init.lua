-- =========================================================================================================================================================
-- Options ---------- Options ---------- Options ---------- Options ---------- Options ---------- Options ---------- Options ---------- Options ---------- O
-- =========================================================================================================================================================

vim.opt.mouse = nil -- Disable mouse
vim.opt.number = true -- Show line numbers
vim.opt.relativenumber = true -- Make line numbers relative to cursor position
vim.opt.wrap = false -- Disable word wrapping
vim.opt.tabstop = 4 -- Set tab size to 4
vim.opt.shiftwidth = 4 -- Set tab size to 4

-- =========================================================================================================================================================
-- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- Plugins ---------- P
-- =========================================================================================================================================================

require("packer").startup(function(use)

	-- Package manager
	use 'wbthomason/packer.nvim'

	-- File tree
	use {
		'nvim-tree/nvim-tree.lua',
		requires = { 'nvim-tree/nvim-web-devicons' },
		config = function()
			-- Start the file tree with default settings
			require("nvim-tree").setup()

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
					lualine_x = {}, -- Remove file encoding
					lualine_y = {
						{
							'filetype',
							fmt = function(str)
								return str:sub(1, 1):upper() .. str:sub(2, str:len())
							end
						}
					},
					lualine_z = {
						{
							'location',
							fmt = function()
								return "Line " .. vim.fn.line(".") .. "/" .. vim.fn.line("$")
							end
						}
					}
				}
			})
		end
	}

	-- Language Server support for diagnostics
	use {
		"williamboman/mason.nvim",
		run = ":MasonUpdate",
		requires = {
			"williamboman/mason-lspconfig",
			"hrsh7th/cmp-nvim-lsp",
			"hrsh7th/nvim-cmp",
			"neovim/nvim-lspconfig"
		},
		config = function()
			require("mason").setup()
			require("mason-lspconfig").setup({
				ensure_installed = {
					'rust_analyzer',
					'tsserver',
					'lua_ls'
				}
			})

			local lsp_capabilities = require('cmp_nvim_lsp').default_capabilities()
			local lsp_attach = function() end

			local lspconfig = require('lspconfig')
			require('mason-lspconfig').setup_handlers({
				function(server_name)
					lspconfig[server_name].setup({
						on_attach = lsp_attach,
						capabilities = lsp_capabilities,
					})
				end,
			})
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
				ensure_installed = { "c", "lua", "rust", "javascript", "typescript" },
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
			wilder.set_option('renderer', wilder.popupmenu_renderer({
				highlights = {
    				accent = wilder.make_hl('WilderAccent', 'Pmenu', {{a = 1}, {a = 1}, {foreground = '#f4468f'}}),
  				},
			}))
		end
	}

end)
