namespace Deliverance.Services;

public static class CollectionSync
{
    public static void Sync<TItem, TRequest>(
        ICollection<TItem> existingItems,
        IEnumerable<TRequest>? incomingItems,
        Func<TItem, string> getExistingKey,
        Func<TRequest, string> getIncomingKey,
        Func<TRequest, TItem> createItem,
        Action<TItem, TRequest> updateItem)
    {
        if (incomingItems == null)
        {
            return;
        }

        var existingByKey = existingItems.ToDictionary(getExistingKey, StringComparer.OrdinalIgnoreCase);
        var incomingKeys = incomingItems.Select(getIncomingKey).ToHashSet(StringComparer.OrdinalIgnoreCase);

        foreach (var item in existingItems.Where(item => !incomingKeys.Contains(getExistingKey(item))).ToList())
        {
            existingItems.Remove(item);
        }

        foreach (var incomingItem in incomingItems)
        {
            if (existingByKey.TryGetValue(getIncomingKey(incomingItem), out var existingItem))
            {
                updateItem(existingItem, incomingItem);
            }
            else
            {
                existingItems.Add(createItem(incomingItem));
            }
        }
    }
}
