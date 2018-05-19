Async filtering
What would that look like?

- Make an animtion for each component to load
- Filtering must be synchronous, but the component pieces can be async
- 

1. Make a messagesWillChange listener
2. Change messagesChanged to messagesDidChange
3. Setup a 'loading' state for each custom view
4. 