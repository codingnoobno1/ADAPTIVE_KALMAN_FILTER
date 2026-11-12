using System.Net.Http.Headers;
using System.Runtime.CompilerServices;
using System.Text.Json;
using Grpc.Core;
using Grpc.Net.Client;
using Livekalman.Common.V1;
using Livekalman.Control.V1;
using Livekalman.Rx.V1;
using Livekalman.Tx.V1;

namespace StreamingLiveKalmanFilter.Maui.Services;

public sealed class LabTelemetryClient(HttpClient http)
{
    static LabTelemetryClient() => AppContext.SetSwitch("System.Net.Http.SocketsHttpHandler.Http2UnencryptedSupport", true);

    public async IAsyncEnumerable<TxFrameTrace> WatchSenderAsync(string endpoint, [EnumeratorCancellation] CancellationToken cancellationToken)
    {
        using var channel = GrpcChannel.ForAddress(NormalizeGrpc(endpoint));
        var client = new TransmitterService.TransmitterServiceClient(channel);
        using var call = client.WatchTxEvents(new Empty(), cancellationToken: cancellationToken);
        while (await call.ResponseStream.MoveNext(cancellationToken))
            if (call.ResponseStream.Current.Trace is not null)
                yield return call.ResponseStream.Current.Trace;
    }

    public async IAsyncEnumerable<RxFrameTrace> WatchReceiverAsync(string endpoint, [EnumeratorCancellation] CancellationToken cancellationToken)
    {
        using var channel = GrpcChannel.ForAddress(NormalizeGrpc(endpoint));
        var client = new ReceiverService.ReceiverServiceClient(channel);
        using var call = client.WatchFrameTraces(new Empty(), cancellationToken: cancellationToken);
        while (await call.ResponseStream.MoveNext(cancellationToken))
            yield return call.ResponseStream.Current;
    }

    public async IAsyncEnumerable<Livekalman.Control.V1.ExperimentEvent> WatchControllerAsync(string endpoint, [EnumeratorCancellation] CancellationToken cancellationToken)
    {
        using var channel = GrpcChannel.ForAddress(NormalizeGrpc(endpoint));
        var client = new ControllerService.ControllerServiceClient(channel);
        using var call = client.WatchExperiment(new WatchRequest(), cancellationToken: cancellationToken);
        while (await call.ResponseStream.MoveNext(cancellationToken))
            yield return call.ResponseStream.Current;
    }

    public async Task<TransferQueue> GetTransfersAsync(string endpoint, CancellationToken cancellationToken)
    {
        var json = await http.GetStringAsync(NormalizeHttp(endpoint, "/api/v1/transfers"), cancellationToken);
        return JsonSerializer.Deserialize<TransferQueue>(json, JsonOptions) ?? new();
    }

    public async Task<string> PickAndSendAsync(string endpoint, string encoding, int key, CancellationToken cancellationToken)
    {
        var picked = await FilePicker.Default.PickAsync(new PickOptions { PickerTitle = "Choose a file to transmit through BPSK" });
        if (picked is null) return "File selection cancelled";
        await using var input = await picked.OpenReadAsync();
        using var content = new StreamContent(input);
        content.Headers.ContentType = new MediaTypeHeaderValue(ContentType(picked.FileName));
        var uri = new UriBuilder(NormalizeHttp(endpoint, "/api/v1/transfers"))
        {
            Query = $"name={Uri.EscapeDataString(picked.FileName)}&encoding={encoding}&key={key}"
        }.Uri;
        using var response = await http.PostAsync(uri, content, cancellationToken);
        var body = await response.Content.ReadAsStringAsync(cancellationToken);
        response.EnsureSuccessStatusCode();
        return $"Queued {picked.FileName}: {body}";
    }

    private static string NormalizeGrpc(string endpoint)
    {
        var value = endpoint.Trim().TrimEnd('/');
        if (value.StartsWith("grpc://", StringComparison.OrdinalIgnoreCase)) value = "http://" + value[7..];
        if (!value.StartsWith("http://", StringComparison.OrdinalIgnoreCase) && !value.StartsWith("https://", StringComparison.OrdinalIgnoreCase)) value = "http://" + value;
        return value;
    }

    private static string NormalizeHttp(string endpoint, string path)
    {
        var value = endpoint.Trim().TrimEnd('/');
        if (!value.StartsWith("http://", StringComparison.OrdinalIgnoreCase) && !value.StartsWith("https://", StringComparison.OrdinalIgnoreCase)) value = "http://" + value;
        return value + path;
    }

    private static string ContentType(string fileName) => Path.GetExtension(fileName).ToLowerInvariant() switch
    {
        ".txt" or ".csv" or ".md" => "text/plain",
        ".json" => "application/json",
        ".bmp" => "image/bmp",
        ".png" => "image/png",
        ".jpg" or ".jpeg" => "image/jpeg",
        ".wav" => "audio/wav",
        _ => "application/octet-stream"
    };

    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };
}

public sealed class TransferQueue
{
    public TransferItem? Active { get; set; }
    public List<TransferItem> Queued { get; set; } = [];
    public List<TransferItem> Recent { get; set; } = [];
    public double BytesPerSecond { get; set; }
    public int MaxTransferBytes { get; set; }
}

public sealed class TransferItem
{
    public string TransferId { get; set; } = "";
    public string FileName { get; set; } = "";
    public string MediaType { get; set; } = "";
    public string Encoding { get; set; } = "";
    public int TotalBytes { get; set; }
    public int SentBytes { get; set; }
    public string State { get; set; } = "";
    public double EstimatedSeconds { get; set; }
}
