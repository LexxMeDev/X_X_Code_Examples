namespace DevAssistent.Core.Interfaces
{
    public interface IService : IGameObject
    {
        IPromise Initialize();
    }
}