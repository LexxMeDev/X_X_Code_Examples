using System.Collections.Generic;
using DevAssistent.DataStructures.Enums;

namespace DevAssistent.Core.Interfaces
{
    public interface IManager : IGameObject
    {
        List<MarketType> Markets { get; }
        bool IsManagerForMarket(MarketType market);
    }
}