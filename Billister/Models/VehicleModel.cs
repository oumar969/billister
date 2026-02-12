using System;

namespace Billister.Models;

public sealed class VehicleModel
{
    public Guid Id { get; set; }

    public Guid MakeId { get; set; }
    public VehicleMake Make { get; set; } = default!;

    public string Name { get; set; } = string.Empty;
}
