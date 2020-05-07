#!/usr/bin/env python
#cython: language_level=3
"""
ビットボードの配置可能位置取得処理
"""

def get_possibles(color, size, b, w, mask):
    """
    石が置ける場所をすべて返す
    """
    if size == 8:
        return _get_possibles_size8(color, b, w)

    return _get_possibles(color, size, b, w, mask)


cdef _get_possibles_size8(color, b, w):
    """
    石が置ける場所をすべて返す(ボードサイズ8限定)
    """
    # 前準備
    player, opponent = (b, w) if color == 'black' else (w, b)  # プレイヤーと相手を決定

    """
     a b c d e f g h
    1■■■■■■■■ … 上位(0)
    2■■■■■■■■
    3■■■■■■■■
    4■■■■■■■■
    5□□□□□□□□ … 下位(1)
    6□□□□□□□□
    7□□□□□□□□
    8□□□□□□□□
    """
    player |= 0x10000000000000000    # 32bit以下でもシフトできるよう対策
    opponent |= 0x10000000000000000

    cdef:
        unsigned int x, y, tmp0, tmp1
        unsigned int p0 = (player >> 32) & 0xFFFFFFFF    # プレイヤー石(上位)
        unsigned int p1 = player & 0xFFFFFFFF            # プレイヤー石(下位)
        unsigned int o0 = (opponent >> 32) & 0xFFFFFFFF  # 相手石(上位)
        unsigned int o1 = opponent & 0xFFFFFFFF          # 相手石(上位)
        unsigned int blank0 = ~(p0 | o0)                 # 空き(上位)
        unsigned int blank1 = ~(p1 | o1)                 # 空き(下位)
        unsigned int horizontal0 = o0 & 0x7E7E7E7E       # 水平方向のマスク値(上位)
        unsigned int horizontal1 = o1 & 0x7E7E7E7E       # 水平方向のマスク値(下位)
        unsigned int vertical0 = o0 & 0x00FFFFFF         # 垂直方向のマスク値(上位)
        unsigned int vertical1 = o1 & 0xFFFFFF00         # 垂直方向のマスク値(下位)
        unsigned int diagonal0 = o0 & 0x007E7E7E         # 斜め方向のマスク値(上位)
        unsigned int diagonal1 = o1 & 0x7E7E7E00         # 斜め方向のマスク値(下位)
        unsigned int possibles0 = 0                      # 石を置ける場所(上位)
        unsigned int possibles1 = 0                      # 石を置ける場所(下位)

    # 左方向に石を置ける場所を探す
    tmp0 = horizontal0 & (p0 << 1)
    tmp0 |= horizontal0 & (tmp0 << 1)
    tmp0 |= horizontal0 & (tmp0 << 1)
    tmp0 |= horizontal0 & (tmp0 << 1)
    tmp0 |= horizontal0 & (tmp0 << 1)
    tmp0 |= horizontal0 & (tmp0 << 1)
    possibles0 |= blank0 & (tmp0 << 1)

    tmp1 = horizontal1 & (p1 << 1)
    tmp1 |= horizontal1 & (tmp1 << 1)
    tmp1 |= horizontal1 & (tmp1 << 1)
    tmp1 |= horizontal1 & (tmp1 << 1)
    tmp1 |= horizontal1 & (tmp1 << 1)
    tmp1 |= horizontal1 & (tmp1 << 1)
    possibles1 |= blank1 & (tmp1 << 1)

    # 右方向に石を置ける場所を探す
    tmp0 = horizontal0 & (p0 >> 1)
    tmp0 |= horizontal0 & (tmp0 >> 1)
    tmp0 |= horizontal0 & (tmp0 >> 1)
    tmp0 |= horizontal0 & (tmp0 >> 1)
    tmp0 |= horizontal0 & (tmp0 >> 1)
    tmp0 |= horizontal0 & (tmp0 >> 1)
    possibles0 |= blank0 & (tmp0 >> 1)

    tmp1 = horizontal1 & (p1 >> 1)
    tmp1 |= horizontal1 & (tmp1 >> 1)
    tmp1 |= horizontal1 & (tmp1 >> 1)
    tmp1 |= horizontal1 & (tmp1 >> 1)
    tmp1 |= horizontal1 & (tmp1 >> 1)
    tmp1 |= horizontal1 & (tmp1 >> 1)
    possibles1 |= blank1 & (tmp1 >> 1)

    # 上方向に石を置ける場所を探す
    tmp1 = vertical1 & (p1 << 8)  # 下位のシフト
    tmp1 |= vertical1 & (tmp1 << 8)
    tmp1 |= vertical1 & (tmp1 << 8)
    possibles1 |= blank1 & (tmp1 << 8)

    tmp0 = vertical0 & ((p0 << 8) | ((tmp1 | p1) >> 24))  # 上位のシフト+下位続き+上位直下にプレイヤー
    tmp0 |= vertical0 & (tmp0 << 8)
    tmp0 |= vertical0 & (tmp0 << 8)
    possibles0 |= blank0 & ((tmp0 << 8) | (tmp1 >> 24))   # 上位のシフト+下位直上で置く場合

    # 下方向に石を置ける場所を探す
    tmp0 = vertical0 & (p0 >> 8)  # 上位のシフト
    tmp0 |= vertical0 & (tmp0 >> 8)
    tmp0 |= vertical0 & (tmp0 >> 8)
    possibles0 |= blank0 & (tmp0 >> 8)

    tmp1 = vertical1 & ((p1 >> 8) | ((tmp0 | p0) << 24))  # 下位のシフト+上位続き+下位直上にプレイヤー
    tmp1 |= vertical1 & (tmp1 >> 8)
    tmp1 |= vertical1 & (tmp1 >> 8)
    possibles1 |= blank1 & ((tmp1 >> 8) | (tmp0 << 24))   # 下位のシフト+上位直下で置く場合

    # 左斜め上方向に石を置ける場所を探す
    tmp1 = diagonal1 & (p1 << 9)  # 下位のシフト
    tmp1 |= diagonal1 & (tmp1 << 9)
    tmp1 |= diagonal1 & (tmp1 << 9)
    possibles1 |= blank1 & (tmp1 << 9)

    tmp0 = diagonal0 & ((p0 << 9) | ((tmp1 | p1) >> 23))  # 上位のシフト+下位続き+上位直下にプレイヤー
    tmp0 |= diagonal0 & (tmp0 << 9)
    tmp0 |= diagonal0 & (tmp0 << 9)
    possibles0 |= blank0 & ((tmp0 << 9) | (tmp1 >> 23))   # 上位のシフト+下位直上で置く場合

    # 左斜め下方向に石を置ける場所を探す
    tmp0 = diagonal0 & (p0 >> 7)  # 上位のシフト
    tmp0 |= diagonal0 & (tmp0 >> 7)
    tmp0 |= diagonal0 & (tmp0 >> 7)
    possibles0 |= blank0 & (tmp0 >> 7)

    tmp1 = diagonal1 & ((p1 >> 7) | ((tmp0 | p0) << 25))  # 下位のシフト+上位続き+下位直上にプレイヤー
    tmp1 |= diagonal1 & (tmp1 >> 7)
    tmp1 |= diagonal1 & (tmp1 >> 7)
    possibles1 |= blank1 & ((tmp1 >> 7) | (tmp0 << 25))   # 下位のシフト+上位直下で置く場合

    # 右斜め上方向に石を置ける場所を探す
    tmp1 = diagonal1 & (p1 << 7)  # 下位のシフト
    tmp1 |= diagonal1 & (tmp1 << 7)
    tmp1 |= diagonal1 & (tmp1 << 7)
    possibles1 |= blank1 & (tmp1 << 7)

    tmp0 = diagonal0 & ((p0 << 7) | ((tmp1 | p1) >> 25))  # 上位のシフト+下位続き+上位直下にプレイヤー
    tmp0 |= diagonal0 & (tmp0 << 7)
    tmp0 |= diagonal0 & (tmp0 << 7)
    possibles0 |= blank0 & ((tmp0 << 7) | (tmp1 >> 25))   # 上位のシフト+下位直上で置く場合

    # 右斜め下方向に石を置ける場所を探す
    tmp0 = diagonal0 & (p0 >> 9)  # 上位のシフト
    tmp0 |= diagonal0 & (tmp0 >> 9)
    tmp0 |= diagonal0 & (tmp0 >> 9)
    possibles0 |= blank0 & (tmp0 >> 9)

    tmp1 = diagonal1 & ((p1 >> 9) | ((tmp0 | p0) << 23))  # 下位のシフト+上位続き+下位直上にプレイヤー
    tmp1 |= diagonal1 & (tmp1 >> 9)
    tmp1 |= diagonal1 & (tmp1 >> 9)
    possibles1 |= blank1 & ((tmp1 >> 9) | (tmp0 << 23))   # 下位のシフト+上位直下で置く場合

    # 石が置ける場所を格納
    ret = {}

    cdef:
        unsigned int mask0 = 0x80000000
        unsigned int mask1 = 0x80000000

    for y in range(8):
        # ビットボード上位32bit
        if y < 4:
            for x in range(8):
                if possibles0 & mask0:
                    ret[(x, y)] = _get_flippable_discs_size8(p0, p1, o0, o1, x, y)
                mask0 >>= 1
        # ビットボード下位32bit
        else:
            for x in range(8):
                if possibles1 & mask1:
                    ret[(x, y)] = _get_flippable_discs_size8(p0, p1, o0, o1, x, y)
                mask1 >>= 1

    return ret


cdef _get_flippable_discs_size8(unsigned int p0, unsigned int p1, unsigned int o0, unsigned int o1, unsigned int x, unsigned int y):
    """
    指定座標のひっくり返せる石の場所をすべて返す(サイズ8限定)
    """
    cdef:
        unsigned int direction, next0, next1, buff0, buff1
        unsigned int put0 = 0              # 石を置く場所(上位)
        unsigned int put1 = 0              # 石を置く場所(下位)
        unsigned int flippable_discs0 = 0  # ひっくり返せる場所(上位)
        unsigned int flippable_discs1 = 0  # ひっくり返せる場所(下位)

    # 石を置く場所
    if y < 4:
        put0 = 1 << (31-(y*8+x))
    else:
        put1 = 1 << (31-((y-4)*8+x))

    # 8方向を順番にチェック
    for direction in range(8):
        buff0, buff1 = 0, 0
        next0, next1 = _get_next_put_size8(put0, put1, direction)

        # 相手の石が存在する限り位置を記憶
        while (next0 & o0) or (next1 & o1):
            buff0 |= next0
            buff1 |= next1
            next0, next1 = _get_next_put_size8(next0, next1, direction)

        # 自分の石で囲まれている場合は結果を格納する
        if (next0 & p0) or (next1 & p1):
            flippable_discs0 |= buff0
            flippable_discs1 |= buff1

    # 配列に変換
    ret = []

    cdef:
        unsigned int mask0 = 0x80000000
        unsigned int mask1 = 0x80000000

    for y in range(8):
        # ビットボード上位32bit
        if y < 4:
            for x in range(8):
                if flippable_discs0 & mask0:
                    ret += [(x, y)]
                mask0 >>= 1
        # ビットボード下位32bit
        else:
            for x in range(8):
                if flippable_discs1 & mask1:
                    ret += [(x, y)]
                mask1 >>= 1

    return ret


cdef _get_next_put_size8(unsigned int put0, unsigned int put1, unsigned int direction):
    """
    指定位置から指定方向に1マス分移動した場所を返す(ボードサイズ8限定)
    """
    cdef:
        unsigned int upper, lower

    if direction == 0:     # 上
        upper = 0xFFFFFFFF & ((put0 << 8) | (put1 >> 24))
        lower = 0xFFFFFF00 & (put1 << 8)
    elif direction == 1:  # 右上
        upper = 0x7F7F7F7F & ((put0 << 7) | (put1 >> 25))
        lower = 0x7F7F7F00 & (put1 << 7)
    elif direction == 2:   # 右
        upper = 0x7F7F7F7F & (put0 >> 1)
        lower = 0x7F7F7F7F & (put1 >> 1)
    elif direction == 3:  # 右下
        upper = 0x007F7F7F & (put0 >> 9)
        lower = 0x7F7F7F7F & ((put1 >> 9) | (put0 << 23))
    elif direction == 4:   # 下
        upper = 0x00FFFFFF & (put0 >> 8)
        lower = 0xFFFFFFFF & ((put1 >> 8) | (put0 << 24))
    elif direction == 5:  # 左下
        upper = 0x00FEFEFE & (put0 >> 7)
        lower = 0xFEFEFEFE & ((put1 >> 7) | (put0 << 25))
    elif direction == 6:   # 左
        upper = 0xFEFEFEFE & (put0 << 1)
        lower = 0xFEFEFEFE & (put1 << 1)
    elif direction == 7:  # 左上
        upper = 0xFEFEFEFE & ((put0 << 9) | (put1 >> 23))
        lower = 0xFEFEFE00 & (put1 << 9)
    else:
        upper, lower = 0, 0

    return upper, lower


cdef _get_possibles(color, size, b, w, mask):
    """
    石が置ける場所をすべて返す(ボードサイズ8以外)
    """
    ret = {}

    # 前準備
    player, opponent = (b, w) if color == 'black' else (w, b)  # プレイヤーと相手を決定
    possibles = 0                                              # 石が置ける場所
    horizontal = opponent & mask.h                             # 水平方向のチェック値
    vertical = opponent & mask.v                               # 垂直方向のチェック値
    diagonal = opponent & mask.d                               # 斜め方向のチェック値
    blank = ~(player | opponent)                               # 空きマス位置

    # 置ける場所を探す
    possibles |= _get_possibles_lshift(size, horizontal, player, blank, 1)     # 左方向
    possibles |= _get_possibles_rshift(size, horizontal, player, blank, 1)     # 右方向
    possibles |= _get_possibles_lshift(size, vertical, player, blank, size)    # 上方向
    possibles |= _get_possibles_rshift(size, vertical, player, blank, size)    # 下方向
    possibles |= _get_possibles_lshift(size, diagonal, player, blank, size+1)  # 左斜め上方向
    possibles |= _get_possibles_lshift(size, diagonal, player, blank, size-1)  # 右斜め上方向
    possibles |= _get_possibles_rshift(size, diagonal, player, blank, size-1)  # 左斜め下方向
    possibles |= _get_possibles_rshift(size, diagonal, player, blank, size+1)  # 右斜め下方向

    # 石が置ける場所を格納
    check = 1 << (size * size - 1)
    for y in range(size):
        for x in range(size):
            # 石が置ける場合
            if possibles & check:
                ret[(x, y)] = _get_flippable_discs(size, player, opponent, x, y, mask)
            check >>= 1

    return ret


cdef _get_flippable_discs(size, player, opponent, x, y, mask):
    """
    指定座標のひっくり返せる石の場所をすべて返す(サイズ8以外)
    """
    ret = []
    flippable_discs = 0

    # 石を置く場所
    put = 1 << ((size*size-1)-(y*size+x))

    # 8方向を順番にチェック
    for direction in ('U', 'UR', 'R', 'BR', 'B', 'BL', 'L', 'UL'):
        tmp = 0
        check = _get_next_put(size, put, direction, mask)

        # 相手の石が存在する限り位置を記憶
        while check & opponent:
            tmp |= check
            check = _get_next_put(size, check, direction, mask)

        # 自分の石で囲まれている場合は結果を格納する
        if check & player:
            flippable_discs |= tmp

    # 配列に変換
    check = 1 << (size*size-1)
    for y in range(size):
        for x in range(size):
            if flippable_discs & check:
                ret += [(x, y)]
            check >>= 1

    return ret


cdef _get_next_put(size, put, direction, mask):
    """
    指定位置から指定方向に1マス分移動した場所を返す(ボードサイズ8以外)
    """
    if direction == 'U':     # 上
        return (put << size) & mask.u
    elif direction == 'UR':  # 右上
        return (put << (size-1)) & mask.ur
    elif direction == 'R':   # 右
        return (put >> 1) & mask.r
    elif direction == 'BR':  # 右下
        return (put >> (size+1)) & mask.br
    elif direction == 'B':   # 下
        return (put >> size) & mask.b
    elif direction == 'BL':  # 左下
        return (put >> (size-1)) & mask.bl
    elif direction == 'L':   # 左
        return (put << 1) & mask.l
    elif direction == 'UL':  # 左上
        return (put << (size+1)) & mask.ul
    else:
        return 0


cdef _get_possibles_lshift(size, mask, player, blank, shift_size):
    """
    左シフトで石が置ける場所を取得
    """
    tmp = mask & (player << shift_size)
    for _ in range(size-3):
        tmp |= mask & (tmp << shift_size)
    return blank & (tmp << shift_size)


cdef _get_possibles_rshift(size, mask, player, blank, shift_size):
    """
    右シフトで石が置ける場所を取得
    """
    tmp = mask & (player >> shift_size)
    for _ in range(size-3):
        tmp |= mask & (tmp >> shift_size)
    return blank & (tmp >> shift_size)


cdef _print_bitboard(bitboard):
    """
    ビットボード表示用
    """
    mask = 0x8000000000000000
    for y in range(8):
        for x in range(8):
            if bitboard & mask:
                print("●", end='')
            else:
                print("□", end='')
            mask >>= 1
        print()


cdef _print_bitboard_half(bitboard):
    """
    ビットボード表示用
    """
    mask = 0x80000000
    for y in range(4):
        for x in range(8):
            if bitboard & mask:
                print("●", end='')
            else:
                print("□", end='')
            mask >>= 1
        print()
