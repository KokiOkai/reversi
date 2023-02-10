from reversi import Simulator
from reversi.strategies import Random, Greedy, AlphaBeta, Switch
from player import CornerPlayer, GreedyPlayer, EdgePlayer, MiniMaxPlayer, NakawariPlayer

if __name__ == '__main__':
    simulator = Simulator(
        {
            # 対戦するPlayer選択
            'RANDOM': Random(),
            'Nakawari': NakawariPlayer(),
        },
    )
    simulator.start()

    print(simulator)
