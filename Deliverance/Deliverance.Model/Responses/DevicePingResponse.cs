namespace Deliverance.Model.Responses;

public class DevicePingResponse
{
    public bool IsOnline { get; set; }
    public long? RoundtripMs { get; set; }
}
