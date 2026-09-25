using System.Runtime.CompilerServices;
using System.Text.Json;
using System.Text.Json.Serialization;

namespace StreamingLiveKalmanFilter.Maui.Services;

public sealed record ReceiverMetrics(
    [property: JsonPropertyName("sequence")] ulong Sequence,
    [property: JsonPropertyName("snr_db")] float SnrDb,
    [property: JsonPropertyName("noise_variance")] float NoiseVariance,
    [property: JsonPropertyName("ber")] float Ber,
    [property: JsonPropertyName("latency_ms")] double LatencyMs,
    [property: JsonPropertyName("active_config_version")] ulong ActiveConfigVersion,
    [property: JsonPropertyName("compared_bits")] ulong ComparedBits,
    [property: JsonPropertyName("bit_errors")] ulong BitErrors,
    [property: JsonPropertyName("queue_depth")] uint QueueDepth,
    [property: JsonPropertyName("observed_at_unix_ms")] ulong ObservedAtUnixMs);

public sealed record ExperimentEvent(
    [property: JsonPropertyName("kind")] string Kind,
    [property: JsonPropertyName("metrics")] ReceiverMetrics? Metrics);

public sealed class ControllerEventClient(HttpClient http)
{
    public async IAsyncEnumerable<ReceiverMetrics> WatchAsync(string endpoint, [EnumeratorCancellation] CancellationToken cancellationToken)
    {
        using var request = new HttpRequestMessage(HttpMethod.Get, endpoint);
        request.Headers.Accept.ParseAdd("text/event-stream");
        using var response = await http.SendAsync(request, HttpCompletionOption.ResponseHeadersRead, cancellationToken);
        response.EnsureSuccessStatusCode();
        await using var stream = await response.Content.ReadAsStreamAsync(cancellationToken);
        using var reader = new StreamReader(stream);
        while (!cancellationToken.IsCancellationRequested)
        {
            var line = await reader.ReadLineAsync(cancellationToken);
            if (line is null) yield break;
            if (!line.StartsWith("data: ", StringComparison.Ordinal)) continue;
            var item = JsonSerializer.Deserialize<ExperimentEvent>(line[6..]);
            if (item is { Kind: "metrics", Metrics: not null }) yield return item.Metrics;
        }
    }
}
