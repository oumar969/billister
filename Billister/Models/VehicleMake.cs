using System;
using System.Collections.Generic;

namespace Billister.Models;

public sealed class VehicleMake
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;

    public List<VehicleModel> Models { get; set; } = new();
}
