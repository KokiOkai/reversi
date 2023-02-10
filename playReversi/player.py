from operator import le
import random
import numpy as np
from reversi.strategies import AbstractStrategy, Timer
 

class CornerPlayer(AbstractStrategy):
    def next_move(self, color, board):
        size = board.size
        legal_moves = board.get_legal_moves(color)
        for corner in [(0, 0), (0, size-1), (size-1, 0), (size-1, size-1)]:
            if corner in legal_moves:
                return corner
 
        return random.choice(legal_moves)
 

class GreedyPlayer(AbstractStrategy):
    def next_move(self, color, board):
        size = board.size
        legal_moves = board.get_legal_moves(color)
        base_score = board._black_score if color == 'black' else board._white_score
        max_score = base_score
        max_move = None
        for move in legal_moves:
            move_x, move_y = move
            score = base_score + len(board.get_flippable_discs(color, move_x, move_y))
            if score > max_score:
                max_score = score
                max_move = move
        return max_move
 

class EdgePlayer(AbstractStrategy):
    def next_move(self, color, board):
        size = board.size
        legal_moves = board.get_legal_moves(color)
        for move in legal_moves:
            move_x, move_y = move
            if move_x in [0, size-1] or move_y in [0, size-1]:
                return move
        return random.choice(legal_moves)
 

class MiniMaxPlayer(AbstractStrategy):
    """decide next move by MinMax method
    """
    def __init__(self, depth=3, evaluator=None):
        self._MIN = -10000000
        self._MAX = 10000000
 
        self.depth = depth
        self.evaluator = evaluator
 
 
    def next_move(self, color, board):
        """next_move
        """
        pid = Timer.get_pid(self)  # タイムアウト監視用のプロセスID
 
        # select best move
        next_color = 'white' if color == 'black' else 'black'
        next_moves = {}
        best_score = self._MIN if color == 'black' else self._MAX
        legal_moves = board.get_legal_moves(color)
        for move in legal_moves:
            board.put_disc(color, *move)
            score = self.get_score(next_color, board, self.depth-1, pid=pid)
            board.undo()
            best_score = max(best_score, score) if color == 'black' else min(best_score, score)
           
            # memorize next moves
            if score not in next_moves:
                next_moves[score] = []
            next_moves[score].append(move)
 
        return random.choice(next_moves[best_score])  # random choice if many best scores
 
    def board_score(self, color, board, possibility_b, possibility_w):
        score = [[100,  30, 50, 50, 50, 50,  30, 100],
                [  30, -25, 45, 45, 45, 45, -25, 30],
                [  50,  45, 50, 50, 50, 50,  45, 50],
                [  50,  45, 50, 50, 50, 50,  45, 50],
                [  50,  45, 50, 50, 50, 50,  45, 50],
                [  50,  45, 50, 50, 50, 50,  45, 50],
                [  30, -25, 45, 45, 45, 45, -25, 30],
                [  100, 30, 50, 50, 50, 50,  30, 100]]
        product = np.multiply(score,board.get_board_info())
        return np.sum(product)
       
        # return self.evaluator.evaluate(color=color, board=board, possibility_b=possibility_b, possibility_w=possibility_w)
 
    def get_score(self, color, board, depth, pid=None):
        """get_score
        """
        # game finish or max-depth
        legal_moves_b_bits = board.get_legal_moves_bits('black')
        legal_moves_w_bits = board.get_legal_moves_bits('white')
        is_game_end = True if not legal_moves_b_bits and not legal_moves_w_bits else False
        if is_game_end or depth <= 0:
            return self.board_score(color=color, board=board, possibility_b=board.get_bit_count(legal_moves_b_bits), possibility_w=board.get_bit_count(legal_moves_w_bits))  # noqa: E501
 
        # in case of pass
        legal_moves_bits = legal_moves_b_bits if color == 'black' else legal_moves_w_bits
        next_color = 'white' if color == 'black' else 'black'
        if not legal_moves_bits:
            return self.get_score(next_color, board, depth, pid=pid)
 
        # get best score
        best_score = self._MIN if color == 'black' else self._MAX
        size = board.size
        mask = 1 << ((size**2)-1)
        for y in range(size):
            for x in range(size):
                if legal_moves_bits & mask:
                    board.put_disc(color, x, y)
                    score = self.get_score(next_color, board, depth-1, pid=pid)
                    board.undo()
                    best_score = max(best_score, score) if color == 'black' else min(best_score, score)
                mask >>= 1
 
        return best_score


class NakawariPlayer(AbstractStrategy):
    def next_move(self, color, board):
        size = board.size
        legal_moves = board.get_legal_moves(color)
        
        # 代入用
        self.size = size
        self.board = board

        # 打てる角は打つ
        for corner in [(0, 0), (0, size-1), (size-1, 0), (size-1, size-1)]:
            if corner in legal_moves:
                return corner
        
        # 中割り
        # 指定座標ごとのひっくり返した石に面している石の数
        contact_moves = []
        for move in legal_moves:
            move_x, move_y = move

            # 指定座標に石を置いたときにひっくり返せる石の場所
            change_pieces = board.get_flippable_discs(color, move_x, move_y)

            # ひっくり返した石に面している石の数
            contact_pieces = []
            for change_piece in change_pieces:
                change_piece_x, change_piece_y = change_piece
                contact_pieces.append(self.get_contact_discs(change_piece_x, change_piece_y))
            
            # 面した石の合計を指定座標ごとに記録
            contact_moves.append(sum(contact_pieces))
        
        # 最善手の配列のindex番号
        index_number = [n for n, x in enumerate(contact_moves) if x == max(contact_moves)]
        # 最適な中割りの手を保存
        select_corner = ()
        select_A = ()
        select_B = ()
        select_box = ()
        select_tyuhen = ()
        select_C = ()
        select_X = ()
        for best_move in index_number:
            # 隅（4つ角）
            for corner in [(0, 0), (0, size-1), (size-1, 0), (size-1, size-1)]:
                if corner == legal_moves[best_move]:
                    select_corner = corner
            # A打ち
            for put_A in [        (0, 2), (0, 5), 
                          (2, 0),                          (2, size-1),
                          (5, 0),                          (5, size-1),
                                  (size-1, 2), (size-1, 5)]:
                if put_A == legal_moves[best_move]:
                    select_A = put_A
            # B打ち
            for put_B in [        (0, 3), (0, 4),
                          (3, 0),                          (3, size-1),
                          (4, 0),                          (4, size-1),
                                  (size-1, 3), (size-1, 4)]:
                if put_B == legal_moves[best_move]:
                    select_B = put_B
            # ボックス
            for put_box in [(2, 2), (2, 3), (2, 4), (2, 5),
                            (3, 2),                 (3, 5),
                            (4, 2),                 (4, 5),
                            (5, 2), (5, 3), (5, 4), (5, 5)]:
                if put_box == legal_moves[best_move]:
                    select_box = put_box
            # 中辺
            for put_tyuhen in [        (1, 2), (1, 3), (1, 4), (1, 5),
                               (2, 1),                                 (2, 6),
                               (3, 1),                                 (3, 6),
                               (4, 1),                                 (4, 6),
                               (5, 1),                                 (5, 6),
                                       (6, 2), (6, 3), (6, 4), (6, 5)]:
                if put_tyuhen == legal_moves[best_move]:
                    select_tyuhen = put_tyuhen
            # C打ち
            for put_C in [        (0, 1),      (0, 6),
                          (1, 0),                          (1, size-1),
                          (6, 0),                          (6, size-1),
                                  (size-1, 1), (size-1, 6)]:
                if put_C == legal_moves[best_move]:
                    select_C = put_C
            # X打ち
            for put_X in [(1, 1), (1, 6), (6, 1), (6, 6)]:
                if put_X == legal_moves[best_move]:
                    select_X = put_X
            
        #  最適な中割りの手を選ぶ（選択肢あり・優先度順）
        if select_corner != ():
            return select_corner
        elif select_A != ():
            return select_A
        elif select_B != ():
            return select_B
        elif select_box != ():
            return select_box
        elif select_tyuhen != ():
            return select_tyuhen
        elif select_C != ():
            return select_C
        elif select_X != ():
            return select_X

        """
        # 最適な中割りの手を選ぶ（選択肢なし）
        return legal_moves[contact_moves.index(max(contact_moves))]
        """

    def get_contact_discs(self, x, y):
        # 指定座標に面している石の数を返す
        # 方向
        directions = [
            (-1,  1), (0,  1), (1,  1),
            (-1,  0),          (1,  0),
            (-1, -1), (0, -1), (1, -1)
        ]
        count = 0
        # 指定座標が範囲内
        if self._in_range(x, y):
            # 8方向をチェック
            for direction in directions:
                dx, dy = direction
                next_x, next_y = x + dx, y + dy
                # 指定座標が範囲内
                if self._in_range(next_x, next_y):
                    # 石が置かれているときカウントする
                    if self._is_color(next_x, next_y):
                        count += 1
        return count
    
    def _in_range(self, x, y):
        # 座標がボードの範囲内の場合True
        return 0 <= x < self.size and 0 <= y < self.size
    
    def _is_blank(self, x, y):
        # 座標上に石が置かれていない(ブランク)場合True
        board_infomation = self.board.get_board_info()
        if board_infomation[x][y] == 0:
            return True
        else:
            return False
    
    def _is_color(self, x, y):
        # 座標上に石が置かれている(黒か白)場合True
        board_infomation = self.board.get_board_info()
        if board_infomation[x][y] == 1 or board_infomation[x][y] == -1:
            return True
        else:
            return False
