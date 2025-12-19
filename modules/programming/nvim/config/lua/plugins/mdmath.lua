return {
    'Thiago4532/mdmath.nvim',
    dependencies = {
        'nvim-treesitter/nvim-treesitter',
    },
    keys = {
        { '<leader>me', '<cmd>MdMath enable<cr>', desc = 'Enable Markdown Math' },
        { '<leader>md', '<cmd>MdMath disable<cr>', desc = 'Disable Markdown Math' },
        { '<leader>mr', '<cmd>MdMath clear<cr>', desc = 'Refresh all equations' },
    },
}
