using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.SignalR;
using System.Security.Claims;

namespace Billister.Hubs;

[Authorize]
public sealed class ChatHub : Hub
{
    /// <summary>
    /// Joins a user to a specific chat thread group.
    /// Users in the same thread group receive broadcast messages.
    /// </summary>
    public async Task JoinThread(string threadId)
    {
        var userId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
            throw new HubException("Unauthorized");

        var groupName = $"thread_{threadId}";
        await Groups.AddToGroupAsync(Context.ConnectionId, groupName);
    }

    /// <summary>
    /// Leaves a chat thread group.
    /// </summary>
    public async Task LeaveThread(string threadId)
    {
        var groupName = $"thread_{threadId}";
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, groupName);
    }

    /// <summary>
    /// Sends a message to all users in the thread group.
    /// Called by the server after saving the message to the database.
    /// </summary>
    public async Task SendMessageToThread(string threadId, string messageJson)
    {
        var groupName = $"thread_{threadId}";
        await Clients.Group(groupName).SendAsync("ReceiveMessage", messageJson);
    }

    /// <summary>
    /// Sends typing indicator to other users in the thread.
    /// </summary>
    public async Task SendTypingIndicator(string threadId, string senderName)
    {
        var groupName = $"thread_{threadId}";
        await Clients.GroupExcept(groupName, Context.ConnectionId).SendAsync("UserIsTyping", senderName);
    }

    /// <summary>
    /// Broadcasts a read receipt to the thread.
    /// </summary>
    public async Task BroadcastReadReceipt(string threadId, string messageId)
    {
        var userId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userId))
            throw new HubException("Unauthorized");

        var groupName = $"thread_{threadId}";
        await Clients.Group(groupName).SendAsync("MessageRead", messageId, userId);
    }

    public override async Task OnConnectedAsync()
    {
        var userId = Context.User?.FindFirstValue(ClaimTypes.NameIdentifier);
        await base.OnConnectedAsync();
    }

    public override async Task OnDisconnectedAsync(Exception? exception)
    {
        await base.OnDisconnectedAsync(exception);
    }
}
