namespace DevAssistent.Core.Services.MessageServices.Interfaces
{
    public interface IMessageSubscriber
    {
    }
    
    public interface IMessageSubscriber<in T> : IMessageSubscriber where T : IMessage
    {
        void OnMessage(T message);
    }
}
