#!/usr/bin/env python
"""
ミニマックス法
"""

import sys
sys.path.append('../')

import random

from reversi.strategies.common import Measure, AbstractStrategy
from reversi.strategies.coordinator import Evaluator_T, Evaluator_TP, Evaluator_TPO, Evaluator_TPW, Evaluator_TPWE, Evaluator_TPWEC, Evaluator_TPOW, Evaluator_PWE


class MinMax(AbstractStrategy):
    """
    MinMax法で次の手を決める
    """
    def __init__(self, depth=3, evaluator=None):
        self._MIN = -10000000
        self._MAX = 10000000

        self.depth = depth
        self.evaluator = evaluator

    @Measure.time
    def next_move(self, color, board):
        """
        次の一手
        """
        next_color = 'white' if color == 'black' else 'black'
        next_moves = {}
        best_score = self._MIN if color == 'black' else self._MAX

        # 打てる手の中から評価値の最も良い手を選ぶ
        for move in board.get_legal_moves(color).keys():
            board.put_disc(color, *move)                             # 一手打つ
            score = self.get_score(next_color, board, self.depth-1)  # 評価値を取得
            board.undo()                                             # 打った手を戻す

            # ベストスコア取得
            best_score = max(best_score, score) if color == 'black' else min(best_score, score)

            # 次の手の候補を記憶
            if score not in next_moves:
                next_moves[score] = []
            next_moves[score].append(move)

        return random.choice(next_moves[best_score])  # 複数候補がある場合はランダムに選ぶ

    def get_score(self, color, board, depth):
        """
        評価値の取得
        """
        # ゲーム終了 or 最大深さに到達
        legal_moves_b = board.get_legal_moves('black', True)  # 黒の打てる場所
        legal_moves_w = board.get_legal_moves('white', True)  # 白の打てる場所
        is_game_end = True if not legal_moves_b and not legal_moves_w else False

        if is_game_end or depth <= 0:
            return self.evaluator.evaluate(color=color, board=board, legal_moves_b=legal_moves_b, legal_moves_w=legal_moves_w)

        # パスの場合
        legal_moves = legal_moves_b if color == 'black' else legal_moves_w
        next_color = 'white' if color == 'black' else 'black'

        if not legal_moves:
            return self.get_score(next_color, board, depth)

        # 評価値を算出
        best_score = self._MIN if color == 'black' else self._MAX

        for move in legal_moves.keys():
            board.put_disc(color, *move)
            score = self.get_score(next_color, board, depth-1)
            board.undo()

            # ベストスコア取得
            best_score = max(best_score, score) if color == 'black' else min(best_score, score)

        return best_score


class MinMax1_T(MinMax):
    """
    MinMax法でEvaluator_Tにより次の手を決める(1手読み)
    """
    def __init__(self, depth=1, evaluator=Evaluator_T()):
        super().__init__(depth, evaluator)


class MinMax2_T(MinMax):
    """
    MinMax法でEvaluator_Tにより次の手を決める(2手読み)
    """
    def __init__(self, depth=2, evaluator=Evaluator_T()):
        super().__init__(depth, evaluator)


class MinMax3_T(MinMax):
    """
    MinMax法でEvaluator_Tにより次の手を決める(3手読み)
    """
    def __init__(self, depth=3, evaluator=Evaluator_T()):
        super().__init__(depth, evaluator)


class MinMax4_T(MinMax):
    """
    MinMax法でEvaluator_Tにより次の手を決める(4手読み)
    """
    def __init__(self, depth=4, evaluator=Evaluator_T()):
        super().__init__(depth, evaluator)


class MinMax1_TP(MinMax):
    """
    MinMax法でEvaluator_TPにより次の手を決める(1手読み)
    """
    def __init__(self, depth=1, evaluator=Evaluator_TP()):
        super().__init__(depth, evaluator)


class MinMax2_TP(MinMax):
    """
    MinMax法でEvaluator_TPにより次の手を決める(2手読み)
    """
    def __init__(self, depth=2, evaluator=Evaluator_TP()):
        super().__init__(depth, evaluator)


class MinMax3_TP(MinMax):
    """
    MinMax法でEvaluator_TPにより次の手を決める(3手読み)
    """
    def __init__(self, depth=3, evaluator=Evaluator_TP()):
        super().__init__(depth, evaluator)


class MinMax4_TP(MinMax):
    """
    MinMax法でEvaluator_TPにより次の手を決める(4手読み)
    """
    def __init__(self, depth=4, evaluator=Evaluator_TP()):
        super().__init__(depth, evaluator)


class MinMax1_TPO(MinMax):
    """
    MinMax法でEvaluator_TPOにより次の手を決める(1手読み)
    """
    def __init__(self, depth=1, evaluator=Evaluator_TPO()):
        super().__init__(depth, evaluator)


class MinMax2_TPO(MinMax):
    """
    MinMax法でEvaluator_TPOにより次の手を決める(2手読み)
    """
    def __init__(self, depth=2, evaluator=Evaluator_TPO()):
        super().__init__(depth, evaluator)


class MinMax3_TPO(MinMax):
    """
    MinMax法でEvaluator_TPOにより次の手を決める(3手読み)
    """
    def __init__(self, depth=3, evaluator=Evaluator_TPO()):
        super().__init__(depth, evaluator)


class MinMax4_TPO(MinMax):
    """
    MinMax法でEvaluator_TPOにより次の手を決める(4手読み)
    """
    def __init__(self, depth=4, evaluator=Evaluator_TPO()):
        super().__init__(depth, evaluator)


class MinMax1_TPW(MinMax):
    """
    MinMax法でEvaluator_TPWにより次の手を決める(1手読み)
    """
    def __init__(self, depth=1, evaluator=Evaluator_TPW()):
        super().__init__(depth, evaluator)


class MinMax1_TPW2(MinMax):
    """
    MinMax法でEvaluator_TPWにより次の手を決める(1手読み)
    """
    def __init__(self, depth=1, evaluator=Evaluator_TPW(corner=50, c=-20, a1=0, a2=22, b=-1, x=-35, o=-5, wp=5, ww=10000)):
        super().__init__(depth, evaluator)


class MinMax1_PWE(MinMax):
    """
    MinMax法でEvaluator_PWEにより次の手を決める(1手読み)
    """
    def __init__(self, depth=1, evaluator=Evaluator_PWE()):
        super().__init__(depth, evaluator)


class MinMax1_TPWE(MinMax):
    """
    MinMax法でEvaluator_TPWEにより次の手を決める(1手読み)
    """
    def __init__(self, depth=1, evaluator=Evaluator_TPWE()):
        super().__init__(depth, evaluator)


class MinMax1_TPWEC(MinMax):
    """
    MinMax法でEvaluator_TPWECにより次の手を決める(1手読み)
    """
    def __init__(self, depth=1, evaluator=Evaluator_TPWEC()):
        super().__init__(depth, evaluator)


class MinMax2_TPW(MinMax):
    """
    MinMax法でEvaluator_TPWにより次の手を決める(2手読み)
    """
    def __init__(self, depth=2, evaluator=Evaluator_TPW()):
        super().__init__(depth, evaluator)


class MinMax2_TPWE(MinMax):
    """
    MinMax法でEvaluator_TPWEにより次の手を決める(2手読み)
    """
    def __init__(self, depth=2, evaluator=Evaluator_TPWE()):
        super().__init__(depth, evaluator)


class MinMax2_TPWEC(MinMax):
    """
    MinMax法でEvaluator_TPWECにより次の手を決める(2手読み)
    """
    def __init__(self, depth=2, evaluator=Evaluator_TPWEC()):
        super().__init__(depth, evaluator)


class MinMax3_TPW(MinMax):
    """
    MinMax法でEvaluator_TPWにより次の手を決める(3手読み)
    """
    def __init__(self, depth=3, evaluator=Evaluator_TPW()):
        super().__init__(depth, evaluator)


class MinMax4_TPW(MinMax):
    """
    MinMax法でEvaluator_TPWにより次の手を決める(4手読み)
    """
    def __init__(self, depth=4, evaluator=Evaluator_TPW()):
        super().__init__(depth, evaluator)


class MinMax1_TPOW(MinMax):
    """
    MinMax法でEvaluator_TPOWにより次の手を決める(1手読み)
    """
    def __init__(self, depth=1, evaluator=Evaluator_TPOW()):
        super().__init__(depth, evaluator)


class MinMax2_TPOW(MinMax):
    """
    MinMax法でEvaluator_TPOWにより次の手を決める(2手読み)
    """
    def __init__(self, depth=2, evaluator=Evaluator_TPOW()):
        super().__init__(depth, evaluator)


class MinMax3_TPOW(MinMax):
    """
    MinMax法でEvaluator_TPOWにより次の手を決める(3手読み)
    """
    def __init__(self, depth=3, evaluator=Evaluator_TPOW()):
        super().__init__(depth, evaluator)


class MinMax4_TPOW(MinMax):
    """
    MinMax法でEvaluator_TPOWにより次の手を決める(4手読み)
    """
    def __init__(self, depth=4, evaluator=Evaluator_TPOW()):
        super().__init__(depth, evaluator)


if __name__ == '__main__':
    from board import BitBoard
    bitboard8 = BitBoard(8)
    print(bitboard8)

    print('--- Test For MinMax Strategy ---')
    minmax = MinMax3_TPOW()

    assert minmax.depth == 3

    bitboard8.put_disc('black', 3, 2)
    print( minmax.get_score('white', bitboard8, 2) )
    assert minmax.get_score('white', bitboard8, 2) == 10.75
    print( minmax.get_score('white', bitboard8, 3) )
    assert minmax.get_score('white', bitboard8, 3) == -6.25

    print(bitboard8)
    print( minmax.next_move('white', bitboard8) )
    assert minmax.next_move('white', bitboard8) == (2, 4)
    bitboard8.put_disc('white', 2, 4)
    bitboard8.put_disc('black', 5, 5)
    bitboard8.put_disc('white', 4, 2)
    bitboard8.put_disc('black', 5, 2)
    bitboard8.put_disc('white', 5, 4)
    print(bitboard8)
    print( minmax.next_move('black', bitboard8) )
    assert minmax.next_move('black', bitboard8) == (2, 2)