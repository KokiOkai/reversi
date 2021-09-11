#cython: language_level=3, profile=False, boundscheck=False, wraparound=False, initializedcheck=False, cdivision=True
"""Next Move(Size8,64bit) of NegaScout
"""

import time

from reversi.strategies.common import Timer, Measure


def next_move(color, board, param_min, param_max, depth, evaluator, pid, timer, measure):
    """next_move
    """
    return _next_move(color, board, param_min, param_max, depth, evaluator, pid, timer, measure)


def get_best_move(color, board, moves, alpha, beta, depth, evaluator, pid, timer, measure):
    """get_best_move
    """
    return _get_best_move_wrap(color, board, moves, alpha, beta, depth, evaluator, pid, timer, measure)


cdef inline tuple _next_move(str color, board, signed int param_min, signed int param_max, int depth, evaluator, str pid, int timer, int measure):
    global legal_moves_bit_list, legal_moves_x, legal_moves_y
    cdef:
        double alpha = param_min, beta = param_max
        unsigned int int_color = 0
    if color == 'black':
        int_color = <unsigned int>1
    moves = board.get_legal_moves(color)  # 手の候補
    best_move, _ = _get_best_move(int_color, board, moves, alpha, beta, depth, evaluator, pid, timer, measure)
    return best_move


cdef inline _get_best_move_wrap(str color, board, moves, double alpha, double beta, int depth, evaluator, str pid, int timer, int measure):
    cdef:
        unsigned int int_color = 0
    if color == 'black':
        int_color = <unsigned int>1
    return _get_best_move(int_color, board, moves, alpha, beta, depth, evaluator, pid, timer, measure)


cdef inline _get_best_move(unsigned int int_color, board, moves, double alpha, double beta, int depth, evaluator, str pid, int timer, int measure):
    global bb, wb, bs, ws
    cdef:
        double score = alpha
        unsigned int int_color_next = 1, i, best = 64
    color = 'white'
    scores = {}
    # 手番
    if int_color:
        int_color_next = <unsigned int>0
        color = 'black'
    # 各手のスコア取得
    best_move = None
    for move in moves:
        board.put_disc(color, *move)
        if timer:
            if measure:  # タイマーあり:メジャーあり
                score = -_get_score_timer_measure(_get_score_timer_measure, int_color_next, board, -beta, -alpha, depth-1, evaluator, pid)
                board.undo()
            else:        # タイマーあり:メジャーなし
                score = -_get_score_timer(_get_score_timer, int_color_next, board, -beta, -alpha, depth-1, evaluator, pid)
                board.undo()
            scores[move] = score
            if Timer.is_timeout(pid):  # タイムアウト判定
                best_move = move if best_move is None else best_move
                break
        elif measure:    # タイマーなし:メジャーあり
            score = -_get_score_measure(_get_score_measure, int_color_next, board, -beta, -alpha, depth-1, evaluator, pid)
            board.undo()
            scores[move] = score
        else:            # タイマーなし:メジャーなし
            score = -_get_score(_get_score, int_color_next, board, -beta, -alpha, depth-1, evaluator, pid)
            board.undo()
            scores[move] = score
        if score > alpha:  # 最善手を更新
            alpha = score
            best_move = move
    return best_move, scores


cdef inline double _get_score_measure(func, unsigned int int_color, board, double alpha, double beta, unsigned int depth, evaluator, str pid):
    """_get_score_measure
    """
    measure(pid)
    return _get_score(func, int_color, board, alpha, beta, depth, evaluator, pid)


cdef inline double _get_score_timer(func, unsigned int int_color, board, double alpha, double beta, unsigned int depth, evaluator, str pid):
    """_get_score_timer
    """
    cdef:
        signed int timeout
    timeout = timer(pid)
    return timeout if timeout else _get_score(func, int_color, board, alpha, beta, depth, evaluator, pid)


cdef inline double _get_score_timer_measure(func, unsigned int int_color, board, double alpha, double beta, unsigned int depth, evaluator, str pid):
    """_get_score_timer_measure
    """
    cdef:
        signed int timeout
    measure(pid)
    timeout = timer(pid)
    return timeout if timeout else _get_score(func, int_color, board, alpha, beta, depth, evaluator, pid)


cdef inline void measure(str pid):
    """measure
    """
    if pid:
        if pid not in Measure.count:
            Measure.count[pid] = 0
        Measure.count[pid] += 1


cdef inline signed int timer(str pid):
    """timer
    """
    if pid:
        if time.time() > Timer.deadline[pid]:
            Timer.timeout_flag[pid] = True  # タイムアウト発生
            return Timer.timeout_value[pid]
    return <signed int>0


cdef double _get_score(func, unsigned int int_color, board, double alpha, double beta, unsigned int depth, evaluator, str pid):
    """_get_score
    """
    cdef:
        double score, tmp, null_window
        unsigned long long b, w, legal_moves_b_bits, legal_moves_w_bits, legal_moves_bits, mask
        unsigned int is_game_end, color_num, x, y, i, count, index = 0
        unsigned int next_moves_x[64]
        unsigned int next_moves_y[64]
        unsigned int int_color_next
        signed int sign
        signed int possibilities[64]

    # ゲーム終了 or 最大深さに到達
    b = board._black_bitboard
    w = board._white_bitboard
    legal_moves_b_bits = _get_legal_moves_bits_size8_64bit(1, b, w)
    legal_moves_w_bits = _get_legal_moves_bits_size8_64bit(0, b, w)
    is_game_end = <unsigned int>1 if not legal_moves_b_bits and not legal_moves_w_bits else <unsigned int>0

    if int_color:
        sign = <signed int>1
        legal_moves_bits = legal_moves_b_bits
        str_color = 'black'
        int_color_next = 0
    else:
        sign = <signed int>-1
        legal_moves_bits = legal_moves_w_bits
        str_color = 'white'
        int_color_next = 1

    if is_game_end or depth == <unsigned int>0:
        return evaluator.evaluate(str_color, board, _get_bit_count_size8_64bit(legal_moves_b_bits), _get_bit_count_size8_64bit(legal_moves_w_bits)) * sign  # noqa: E501

    # パスの場合
    if not legal_moves_bits:
        return -func(func, int_color_next, board, -beta, -alpha, depth, evaluator, pid)

    # 着手可能数に応じて手を並び替え
    count = 0
    mask = 1 << 63
    for y in range(8):
        for x in range(8):
            if legal_moves_bits & mask:
                next_moves_x[count] = x
                next_moves_y[count] = y
                possibilities[count] = _get_possibility_size8_64bit(board, int_color, x, y, sign)
                count += 1
            mask >>= 1

    _sort_moves_by_possibility(count, next_moves_x, next_moves_y, possibilities)

    # 次の手の探索
    null_window = beta
    for i in range(count):
        if alpha < beta:
            _put_disc_size8_64bit(board, int_color, next_moves_x[i], next_moves_y[i])
            tmp = -func(func, int_color_next, board, -null_window, -alpha, depth-1, evaluator, pid)
            _undo(board)

            if alpha < tmp:
                if tmp <= null_window and index:
                    _put_disc_size8_64bit(board, int_color, next_moves_x[i], next_moves_y[i])
                    alpha = -func(func, int_color_next, board, -beta, -tmp, depth-1, evaluator, pid)
                    _undo(board)

                    if Timer.is_timeout(pid):
                        return alpha
                else:
                    alpha = tmp

            null_window = alpha + 1
        else:
            return alpha

        index += <unsigned int>1

    return alpha


cdef inline unsigned long long _get_legal_moves_bits_size8_64bit(unsigned int color, unsigned long long b, unsigned long long w):
    """_get_legal_moves_bits_size8_64bit
    """
    cdef:
        unsigned long long player, opponent

    if color:
        player = b
        opponent = w
    else:
        player = w
        opponent = b

    cdef:
        unsigned long long blank = ~(player | opponent)
        unsigned long long horizontal = opponent & <unsigned long long>0x7E7E7E7E7E7E7E7E  # horizontal mask value
        unsigned long long vertical = opponent & <unsigned long long>0x00FFFFFFFFFFFF00    # vertical mask value
        unsigned long long diagonal = opponent & <unsigned long long>0x007E7E7E7E7E7E00    # diagonal mask value
        unsigned long long tmp_h, tmp_v, tmp_d1, tmp_d2

    # left/right
    tmp_h = horizontal & ((player << 1) | (player >> 1))
    tmp_h |= horizontal & ((tmp_h << 1) | (tmp_h >> 1))
    tmp_h |= horizontal & ((tmp_h << 1) | (tmp_h >> 1))
    tmp_h |= horizontal & ((tmp_h << 1) | (tmp_h >> 1))
    tmp_h |= horizontal & ((tmp_h << 1) | (tmp_h >> 1))
    tmp_h |= horizontal & ((tmp_h << 1) | (tmp_h >> 1))

    # top/bottom
    tmp_v = vertical & ((player << 8) | (player >> 8))
    tmp_v |= vertical & ((tmp_v << 8) | (tmp_v >> 8))
    tmp_v |= vertical & ((tmp_v << 8) | (tmp_v >> 8))
    tmp_v |= vertical & ((tmp_v << 8) | (tmp_v >> 8))
    tmp_v |= vertical & ((tmp_v << 8) | (tmp_v >> 8))
    tmp_v |= vertical & ((tmp_v << 8) | (tmp_v >> 8))

    # left-top/right-bottom
    tmp_d1 = diagonal & ((player << 9) | (player >> 9))
    tmp_d1 |= diagonal & ((tmp_d1 << 9) | (tmp_d1 >> 9))
    tmp_d1 |= diagonal & ((tmp_d1 << 9) | (tmp_d1 >> 9))
    tmp_d1 |= diagonal & ((tmp_d1 << 9) | (tmp_d1 >> 9))
    tmp_d1 |= diagonal & ((tmp_d1 << 9) | (tmp_d1 >> 9))
    tmp_d1 |= diagonal & ((tmp_d1 << 9) | (tmp_d1 >> 9))

    # right-top/left-bottom
    tmp_d2 = diagonal & ((player << 7) | (player >> 7))
    tmp_d2 |= diagonal & ((tmp_d2 << 7) | (tmp_d2 >> 7))
    tmp_d2 |= diagonal & ((tmp_d2 << 7) | (tmp_d2 >> 7))
    tmp_d2 |= diagonal & ((tmp_d2 << 7) | (tmp_d2 >> 7))
    tmp_d2 |= diagonal & ((tmp_d2 << 7) | (tmp_d2 >> 7))
    tmp_d2 |= diagonal & ((tmp_d2 << 7) | (tmp_d2 >> 7))

    return blank & ((tmp_h << 1) | (tmp_h >> 1) | (tmp_v << 8) | (tmp_v >> 8) | (tmp_d1 << 9) | (tmp_d1 >> 9) | (tmp_d2 << 7) | (tmp_d2 >> 7))


cdef inline unsigned long long _get_bit_count_size8_64bit(unsigned long long bits):
    """_get_bit_count_size8_64bit
    """
    bits = (bits & <unsigned long long>0x5555555555555555) + (bits >> <unsigned int>1 & <unsigned long long>0x5555555555555555)
    bits = (bits & <unsigned long long>0x3333333333333333) + (bits >> <unsigned int>2 & <unsigned long long>0x3333333333333333)
    bits = (bits & <unsigned long long>0x0F0F0F0F0F0F0F0F) + (bits >> <unsigned int>4 & <unsigned long long>0x0F0F0F0F0F0F0F0F)
    bits = (bits & <unsigned long long>0x00FF00FF00FF00FF) + (bits >> <unsigned int>8 & <unsigned long long>0x00FF00FF00FF00FF)
    bits = (bits & <unsigned long long>0x0000FFFF0000FFFF) + (bits >> <unsigned int>16 & <unsigned long long>0x0000FFFF0000FFFF)

    return (bits & <unsigned long long>0x00000000FFFFFFFF) + (bits >> <unsigned int>32 & <unsigned long long>0x00000000FFFFFFFF)


cdef inline unsigned long long _put_disc_size8_64bit(board, unsigned int color, unsigned int x, unsigned int y):
    """_put_disc_size8_64bit
    """
    cdef:
        unsigned long long put, black_bitboard, white_bitboard, flippable_discs_num, flippable_discs_count
        unsigned int black_score, white_score
        signed int shift_size

    # 配置位置を整数に変換
    shift_size = (63-(y*8+x))
    put = <unsigned long long>1 << shift_size

    # ひっくり返せる石を取得
    black_bitboard = board._black_bitboard
    white_bitboard = board._white_bitboard
    black_score = board._black_score
    white_score = board._white_score
    flippable_discs_num = _get_flippable_discs_num_size8_64bit(color, black_bitboard, white_bitboard, shift_size)
    flippable_discs_count = _get_bit_count_size8_64bit(flippable_discs_num)

    # 打つ前の状態を格納
    board.prev += [(black_bitboard, white_bitboard, black_score, white_score)]

    # 自分の石を置いて相手の石をひっくり返す
    if color:
        black_bitboard ^= put | flippable_discs_num
        white_bitboard ^= flippable_discs_num
        black_score += <unsigned int>1 + <unsigned int>flippable_discs_count
        white_score -= <unsigned int>flippable_discs_count
    else:
        white_bitboard ^= put | flippable_discs_num
        black_bitboard ^= flippable_discs_num
        black_score -= <unsigned int>flippable_discs_count
        white_score += <unsigned int>1 + <unsigned int>flippable_discs_count

    board._black_bitboard = black_bitboard
    board._white_bitboard = white_bitboard
    board._black_score = black_score
    board._white_score = white_score
    board._flippable_discs_num = flippable_discs_num

    return flippable_discs_num


cdef inline unsigned long long _get_flippable_discs_num_size8_64bit(unsigned int color, unsigned long long black_bitboard, unsigned long long white_bitboard, unsigned int shift_size):
    """_get_flippable_discs_size8_64bit
    """
    cdef:
        unsigned int direction1, direction2
        unsigned long long buff, next_put
        unsigned long long move = 0
        unsigned long long player, opponent, flippable_discs_num = 0

    if color:
        player = black_bitboard
        opponent = white_bitboard
    else:
        player = white_bitboard
        opponent = black_bitboard

    move = <unsigned long long>1 << shift_size

    for direction1 in range(8):
        buff = 0
        next_put = _get_next_put_size8_64bit(move, direction1)

        # get discs of consecutive opponents
        for direction2 in range(8):
            if next_put & opponent:
                buff |= next_put
                next_put = _get_next_put_size8_64bit(next_put, direction1)
            else:
                break

        # store result if surrounded by own disc
        if next_put & player:
            flippable_discs_num |= buff

    return flippable_discs_num


cdef inline unsigned long long _get_next_put_size8_64bit(unsigned long long put, unsigned int direction):
    """_get_next_put_size8_64bit
    """
    cdef:
        unsigned long long next_put

    if direction == 0:
        next_put = <unsigned long long>0xFFFFFFFFFFFFFF00 & (put << <unsigned int>8)  # top
    elif direction == 1:
        next_put = <unsigned long long>0x7F7F7F7F7F7F7F00 & (put << <unsigned int>7)  # right-top
    elif direction == 2:
        next_put = <unsigned long long>0x7F7F7F7F7F7F7F7F & (put >> <unsigned int>1)  # right
    elif direction == 3:
        next_put = <unsigned long long>0x007F7F7F7F7F7F7F & (put >> <unsigned int>9)  # right-bottom
    elif direction == 4:
        next_put = <unsigned long long>0x00FFFFFFFFFFFFFF & (put >> <unsigned int>8)  # bottom
    elif direction == 5:
        next_put = <unsigned long long>0x00FEFEFEFEFEFEFE & (put >> <unsigned int>7)  # left-bottom
    elif direction == 6:
        next_put = <unsigned long long>0xFEFEFEFEFEFEFEFE & (put << <unsigned int>1)  # left
    elif direction == 7:
        next_put = <unsigned long long>0xFEFEFEFEFEFEFE00 & (put << <unsigned int>9)  # left-top
    else:
        next_put = <unsigned long long>0                                              # unexpected

    return next_put


cdef inline _undo(board):
    """_undo
    """
    (board._black_bitboard, board._white_bitboard, board._black_score, board._white_score) = board.prev.pop()


cdef inline signed int _get_possibility_size8_64bit(board, unsigned int color, unsigned int x, unsigned int y, signed int sign):
    """_get_possibility_size8_64bit
    """
    cdef:
        unsigned long long put, black_bitboard, white_bitboard, flippable_discs_num
        signed int shift_size, possibility_b, possibility_w

    # 配置位置を整数に変換
    shift_size = (63-(y*8+x))
    put = <unsigned long long>1 << shift_size

    # ひっくり返せる石を取得
    black_bitboard = board._black_bitboard
    white_bitboard = board._white_bitboard
    flippable_discs_num = _get_flippable_discs_num_size8_64bit(color, black_bitboard, white_bitboard, shift_size)

    # 自分の石を置いて相手の石をひっくり返す
    if color:
        black_bitboard ^= put | flippable_discs_num
        white_bitboard ^= flippable_discs_num
    else:
        white_bitboard ^= put | flippable_discs_num
        black_bitboard ^= flippable_discs_num

    possibility_b = <signed int>_get_bit_count_size8_64bit(_get_legal_moves_bits_size8_64bit(1, black_bitboard, white_bitboard))
    possibility_w = <signed int>_get_bit_count_size8_64bit(_get_legal_moves_bits_size8_64bit(0, black_bitboard, white_bitboard))

    return (possibility_b - possibility_w) * sign


cdef inline _sort_moves_by_possibility(unsigned int count, unsigned int *next_moves_x, unsigned int *next_moves_y, signed int *possibilities):
    """_sort_moves_by_possibility
    """
    cdef:
        unsigned int len1, len2, i
        unsigned int array_x1[64]
        unsigned int array_x2[64]
        unsigned int array_y1[64]
        unsigned int array_y2[64]
        signed int array_p1[64]
        signed int array_p2[64]

    # merge sort
    if count > 1:
        len1 = <unsigned int>(count / 2)
        len2 = <unsigned int>(count - len1)
        for i in range(len1):
            array_x1[i] = next_moves_x[i]
            array_y1[i] = next_moves_y[i]
            array_p1[i] = possibilities[i]
        for i in range(len2):
            array_x2[i] = next_moves_x[len1+i]
            array_y2[i] = next_moves_y[len1+i]
            array_p2[i] = possibilities[len1+i]
        _sort_moves_by_possibility(len1, array_x1, array_y1, array_p1)
        _sort_moves_by_possibility(len2, array_x2, array_y2, array_p2)
        _merge(len1, len2, array_x1, array_y1, array_p1, array_x2, array_y2, array_p2, next_moves_x, next_moves_y, possibilities)


cdef inline _merge(unsigned int len1, unsigned int len2, unsigned int *array_x1, unsigned int *array_y1, signed int *array_p1, unsigned int *array_x2, unsigned int *array_y2, signed int *array_p2, unsigned int *next_moves_x, unsigned int *next_moves_y, signed int *possibilities):
    """_merge
    """
    cdef:
        unsigned int i = 0, j = 0

    while i < len1 or j < len2:
        # descending sort
        if j >= len2 or (i < len1 and array_p1[i] >= array_p2[j]):
            next_moves_x[i+j] = array_x1[i]
            next_moves_y[i+j] = array_y1[i]
            possibilities[i+j] = array_p1[i]
            i += 1
        else:
            next_moves_x[i+j] = array_x2[j]
            next_moves_y[i+j] = array_y2[j]
            possibilities[i+j] = array_p2[j]
            j += 1
