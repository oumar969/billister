using Microsoft.AspNetCore.SignalR;
using Microsoft.EntityFrameworkCore;
using Billister.Data;
using Billister.Models;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;

namespace Billister.Services
{
    public class ChatHub : Hub
    {
        private readonly BillisterDbContext _context;
        private readonly ILogger<ChatHub> _logger;

        // Track which users are in which threads
        private static Dictionary<string, HashSet<string>> ThreadUsers = new();

        public ChatHub(BillisterDbContext context, ILogger<ChatHub> logger)
        {
            _context = context;
            _logger = logger;
        }

        public override async Task OnConnectedAsync()
        {
            var userId = Context.User?.FindFirst("sub")?.Value ?? Context.ConnectionId;
            _logger.LogInformation($"User {userId} connected via SignalR. ConnectionId: {Context.ConnectionId}");
            await base.OnConnectedAsync();
        }

        public override async Task OnDisconnectedAsync(Exception? exception)
        {
            var userId = Context.User?.FindFirst("sub")?.Value ?? Context.ConnectionId;
            _logger.LogInformation($"User {userId} disconnected from SignalR. Reason: {exception?.Message}");

            // Remove user from all threads they were in
            var threadsToNotify = new List<string>();
            foreach (var kvp in ThreadUsers.ToList())
            {
                if (kvp.Value.Contains(userId))
                {
                    kvp.Value.Remove(userId);
                    threadsToNotify.Add(kvp.Key);
                }
            }

            // Notify remaining users in those threads
            foreach (var threadId in threadsToNotify)
            {
                await Clients.Group(threadId).SendAsync("UserDisconnected", userId);
            }

            await base.OnDisconnectedAsync(exception);
        }

        /// <summary>
        /// Join a chat thread and start receiving real-time messages
        /// </summary>
        public async Task JoinThread(string threadId)
        {
            try
            {
                var userId = Context.User?.FindFirst("sub")?.Value;
                if (string.IsNullOrEmpty(userId))
                {
                    await Clients.Caller.SendAsync("Error", "Unauthorized");
                    return;
                }

                // Verify user has access to this thread
                if (!Guid.TryParse(threadId, out var threadGuid))
                {
                    await Clients.Caller.SendAsync("Error", "Invalid thread ID");
                    return;
                }

                if (!Guid.TryParse(userId, out var userGuid))
                {
                    await Clients.Caller.SendAsync("Error", "Invalid user ID");
                    return;
                }

                var thread = await _context.ChatThreads
                    .FirstOrDefaultAsync(ct => ct.Id == threadGuid &&
                        (ct.BuyerId == userGuid || ct.SellerId == userGuid));

                if (thread == null)
                {
                    await Clients.Caller.SendAsync("Error", "Thread not found or access denied");
                    return;
                }

                // Add user to thread group
                await Groups.AddToGroupAsync(Context.ConnectionId, threadId);

                // Track user in thread
                if (!ThreadUsers.ContainsKey(threadId))
                {
                    ThreadUsers[threadId] = new HashSet<string>();
                }
                ThreadUsers[threadId].Add(userId);

                // Notify others that user joined
                await Clients.GroupExcept(threadId, Context.ConnectionId)
                    .SendAsync("UserConnected", userId);

                _logger.LogInformation($"User {userId} joined thread {threadId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error joining thread");
                await Clients.Caller.SendAsync("Error", "Failed to join thread");
            }
        }

        /// <summary>
        /// Leave a chat thread
        /// </summary>
        public async Task LeaveThread(string threadId)
        {
            try
            {
                var userId = Context.User?.FindFirst("sub")?.Value;
                if (string.IsNullOrEmpty(userId))
                    return;

                await Groups.RemoveFromGroupAsync(Context.ConnectionId, threadId);

                if (ThreadUsers.ContainsKey(threadId))
                {
                    ThreadUsers[threadId].Remove(userId);
                }

                // Notify others that user left
                await Clients.Group(threadId).SendAsync("UserDisconnected", userId);

                _logger.LogInformation($"User {userId} left thread {threadId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error leaving thread");
            }
        }

        /// <summary>
        /// Send a message to a chat thread
        /// </summary>
        public async Task SendMessage(string threadId, string content)
        {
            try
            {
                var userId = Context.User?.FindFirst("sub")?.Value;
                if (string.IsNullOrEmpty(userId) || string.IsNullOrEmpty(content?.Trim()))
                {
                    await Clients.Caller.SendAsync("Error", "Invalid message");
                    return;
                }

                if (!Guid.TryParse(threadId, out var threadGuid))
                {
                    await Clients.Caller.SendAsync("Error", "Invalid thread ID");
                    return;
                }

                if (!Guid.TryParse(userId, out var userGuid))
                {
                    await Clients.Caller.SendAsync("Error", "Invalid user ID");
                    return;
                }

                // Verify user has access to this thread
                var thread = await _context.ChatThreads
                    .FirstOrDefaultAsync(ct => ct.Id == threadGuid &&
                        (ct.BuyerId == userGuid || ct.SellerId == userGuid));

                if (thread == null)
                {
                    await Clients.Caller.SendAsync("Error", "Thread not found");
                    return;
                }

                // Determine receiver ID (other participant in the thread)
                var receiverId = thread.BuyerId == userGuid ? thread.SellerId : thread.BuyerId;

                // Create message
                var message = new ChatMessage
                {
                    Id = Guid.NewGuid(),
                    ChatThreadId = threadGuid,
                    SenderId = userGuid,
                    ReceiverId = receiverId,
                    Content = content.Trim(),
                    CreatedAtUtc = DateTime.UtcNow,
                    IsRead = false
                };

                _context.ChatMessages.Add(message);
                await _context.SaveChangesAsync();

                // Broadcast message to all users in thread
                await Clients.Group(threadId).SendAsync("ReceiveMessage", new
                {
                    id = message.Id,
                    chatThreadId = message.ChatThreadId,
                    senderId = message.SenderId,
                    receiverId = message.ReceiverId,
                    content = message.Content,
                    isRead = message.IsRead,
                    createdAtUtc = message.CreatedAtUtc
                });

                _logger.LogInformation($"Message from {userId} in thread {threadId}");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending message");
                await Clients.Caller.SendAsync("Error", "Failed to send message");
            }
        }

        /// <summary>
        /// Notify others that user is typing
        /// </summary>
        public async Task UserIsTyping(string threadId)
        {
            try
            {
                var userId = Context.User?.FindFirst("sub")?.Value;
                if (string.IsNullOrEmpty(userId))
                    return;

                await Clients.GroupExcept(threadId, Context.ConnectionId)
                    .SendAsync("UserTyping", userId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error notifying typing");
            }
        }

        /// <summary>
        /// Notify others that user stopped typing
        /// </summary>
        public async Task UserStoppedTyping(string threadId)
        {
            try
            {
                var userId = Context.User?.FindFirst("sub")?.Value;
                if (string.IsNullOrEmpty(userId))
                    return;

                await Clients.GroupExcept(threadId, Context.ConnectionId)
                    .SendAsync("UserStoppedTyping", userId);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error notifying stopped typing");
            }
        }

        /// <summary>
        /// Mark a message as read by current user
        /// </summary>
        public async Task MarkMessageAsRead(string messageId, string threadId)
        {
            try
            {
                var userId = Context.User?.FindFirst("sub")?.Value;
                if (string.IsNullOrEmpty(userId))
                    return;

                if (!Guid.TryParse(messageId, out var messageGuid))
                    return;

                var message = await _context.ChatMessages
                    .FirstOrDefaultAsync(m => m.Id == messageGuid);

                if (message == null)
                    return;

                // Mark as read if not already
                if (!message.IsRead)
                {
                    message.IsRead = true;
                    message.ReadAtUtc = DateTime.UtcNow;
                    await _context.SaveChangesAsync();
                }

                // Broadcast read receipt to all users in thread
                await Clients.Group(threadId).SendAsync("MessageRead", messageId, userId);

                _logger.LogInformation($"User {userId} marked message {messageId} as read");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error marking message as read");
            }
        }
    }
}

