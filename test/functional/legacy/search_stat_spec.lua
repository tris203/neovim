local n = require('test.functional.testnvim')()
local Screen = require('test.functional.ui.screen')

local clear, feed, exec, command = n.clear, n.feed, n.exec, n.command

describe('search stat', function()
  local screen
  before_each(function()
    clear()
    screen = Screen.new(30, 10)
  end)

  -- oldtest: Test_search_stat_screendump()
  it('right spacing with silent mapping vim-patch:8.1.1970', function()
    exec([[
      set shortmess-=S
      " Append 50 lines with text to search for, "foobar" appears 20 times
      call append(0, repeat(['foobar', 'foo', 'fooooobar', 'foba', 'foobar'], 20))
      call setline(2, 'find this')
      call setline(70, 'find this')
      nnoremap n n
      let @/ = 'find this'
      call cursor(1,1)
      norm n
    ]])
    screen:expect([[
      foobar                        |
      {10:^find this}                     |
      fooooobar                     |
      foba                          |
      foobar                        |*2
      foo                           |
      fooooobar                     |
      foba                          |
      /find this             [1/2]  |
    ]])
    command('nnoremap <silent> n n')
    feed('gg0n')
    screen:expect([[
      foobar                        |
      {10:^find this}                     |
      fooooobar                     |
      foba                          |
      foobar                        |*2
      foo                           |
      fooooobar                     |
      foba                          |
                             [1/2]  |
    ]])
  end)

  -- oldtest: Test_search_stat_foldopen()
  it('when only match is in fold vim-patch:8.2.0840', function()
    exec([[
      set shortmess-=S
      setl foldenable foldmethod=indent foldopen-=search
      call append(0, ['if', "\tfoo", "\tfoo", 'endif'])
      let @/ = 'foo'
      call cursor(1,1)
      norm n
    ]])
    screen:expect([[
      if                            |
      {13:^+--  2 lines: foo·············}|
      endif                         |
                                    |
      {1:~                             }|*5
      /foo                   [1/2]  |
    ]])
    -- Note: there is an intermediate state where the search stat disappears.
    feed('n')
    screen:expect_unchanged(true)
    feed('n')
    screen:expect_unchanged(true)
  end)

  -- oldtest: Test_search_stat_then_gd()
  it('is cleared by gd and gD vim-patch:8.2.3583', function()
    exec([[
      call setline(1, ['int cat;', 'int dog;', 'cat = dog;'])
      set shortmess-=S
      set hlsearch
    ]])
    feed('/dog<CR>')
    screen:expect([[
      int cat;                      |
      int {10:^dog};                      |
      cat = {10:dog};                    |
      {1:~                             }|*6
      /dog                   [1/2]  |
    ]])
    feed('G0gD')
    screen:expect([[
      int {10:^cat};                      |
      int dog;                      |
      {10:cat} = dog;                    |
      {1:~                             }|*6
                                    |
    ]])
  end)

  -- oldtest: Test_search_stat_and_incsearch()
  it('is not broken by calling searchcount() in tabline vim-patch:8.2.4378', function()
    exec([[
      call setline(1, ['abc--c', '--------abc', '--abc'])
      set hlsearch
      set incsearch
      set showtabline=2

      function MyTabLine()
      try
        let a=searchcount(#{recompute: 1, maxcount: -1})
        return a.current .. '/' .. a.total
      catch
        return ''
      endtry
      endfunction

      set tabline=%!MyTabLine()
    ]])

    feed('/abc')
    screen:expect([[
      {2:                              }|
      {10:abc}--c                        |
      --------{2:abc}                   |
      --{10:abc}                         |
      {1:~                             }|*5
      /abc^                          |
    ]])

    feed('<C-G>')
    screen:expect([[
      {2:3/3                           }|
      {10:abc}--c                        |
      --------{10:abc}                   |
      --{2:abc}                         |
      {1:~                             }|*5
      /abc^                          |
    ]])

    feed('<C-G>')
    screen:expect([[
      {2:1/3                           }|
      {2:abc}--c                        |
      --------{10:abc}                   |
      --{10:abc}                         |
      {1:~                             }|*5
      /abc^                          |
    ]])
  end)

  -- oldtest: Test_search_stat_backwards()
  it('when searching backwards', function()
    screen:try_resize(60, 10)
    exec([[
      set shm-=S
      call setline(1, ['test', ''])
    ]])

    feed('*')
    screen:expect([[
      {10:^test}                                                        |
                                                                  |
      {1:~                                                           }|*7
      /\<test\>                                            [1/1]  |
    ]])

    feed('N')
    screen:expect([[
      {10:^test}                                                        |
                                                                  |
      {1:~                                                           }|*7
      ?\<test\>                                            [1/1]  |
    ]])

    command('set shm+=S')
    feed('N')
    -- shows "Search Hit Bottom.."
    screen:expect([[
      {10:^test}                                                        |
                                                                  |
      {1:~                                                           }|*7
      {19:search hit TOP, continuing at BOTTOM}                        |
    ]])
  end)

  -- oldtest: Test_search_stat_smartcase_ignorecase()
  it('when changing case of pattern', function()
    exec([[
      set shm-=S ignorecase smartcase
      call setline(1, [' MainmainmainmmmainmAin', ''])
    ]])

    feed('/main<cr>nnnn')
    screen:expect([[
       {10:Mainmainmain}mm{10:main^mAin}       |
                                    |
      {1:~                             }|*7
      /main                  [5/5]  |
    ]])

    feed('/mAin<cr>')
    screen:expect([[
       Mainmainmainmmmain{10:^mAin}       |
                                    |
      {1:~                             }|*7
      /mAin                  [1/1]  |
    ]])
  end)
end)
