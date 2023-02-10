from reversi import Reversi
from reversi.strategies import Random, Greedy, AlphaBeta, Switch
from player import CornerPlayer, GreedyPlayer, EdgePlayer, MiniMaxPlayer, NakawariPlayer
from reversi.strategies.coordinator import Evaluator

if __name__ == '__main__':
    Reversi(
        {
            #add player
            'RANDOM': Random(),
            'GREEDY': GreedyPlayer(),
            'Corner': CornerPlayer(),
            'MINMAX': MiniMaxPlayer(depth = 3),
            'Edge' : EdgePlayer(),
            'Nakawari' : NakawariPlayer(),
            'SWITCH': Switch(
                turns=[
                    49,    # 1～50手目まではNakawari        (30手目-1を設定)
                    60     # それ以降(残り10手)からはMiniMax(最後は60を設定)
                ],
                strategies=[
                    NakawariPlayer(),
                    MiniMaxPlayer(depth = 3) 
                ],
            ),
        }
    ).start()
