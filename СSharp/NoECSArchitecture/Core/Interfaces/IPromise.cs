using System;

namespace DevAssistent.Core.Interfaces
{
    public interface IPromise
    {
        IPromise Done(Action callback);
        IPromise Fail(Action<Exception> callback);
        IPromise Always(Action callback);
        IPromise Then(Func<IPromise> next);
    }

    public interface IPromise<T> : IPromise
    {
        IPromise<T> Done(Action<T> callback);
    }
}