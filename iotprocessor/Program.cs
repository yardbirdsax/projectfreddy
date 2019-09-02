using System;
using Microsoft.Azure.EventHubs;
using Microsoft.Azure.EventHubs.Processor;
using System.Threading.Tasks;
using System.Threading;
using Serilog;
using Serilog.Events;
using System.Runtime.Loader;
using Prometheus;
using Newtonsoft.Json;

namespace iotprocessor
{
    class IotRecord
    {
        string _Device;
        float _Temp;

        public string Device { get => _Device; set => _Device = value; }
        public float Temp { get => _Temp; set => _Temp = value; }
    }

    class Program
    {
        #region variables
        static readonly string strEventHubConnectionString = System.Environment.GetEnvironmentVariable("event_hub_connection_string");
        static readonly string strEventHubName = System.Environment.GetEnvironmentVariable("event_hub_name");
        static readonly string strStorageContainerName = System.Environment.GetEnvironmentVariable("storage_container_name");
        static readonly string strStorageAccountName = System.Environment.GetEnvironmentVariable("storage_account_name");
        static readonly string strStorageAccountKey = System.Environment.GetEnvironmentVariable("storage_account_key");
        static readonly string strStorageAccountConnectionString = string.Format("DefaultEndpointsProtocol=https;AccountName={0};AccountKey={1}", strStorageAccountName, strStorageAccountKey);  
        static readonly string strLogLevel = System.Environment.GetEnvironmentVariable("log_level");
        #endregion

        static void Main(string[] args)
        {
            
            LogEventLevel logLevel = LogEventLevel.Information;
            bool res = Enum.TryParse<Serilog.Events.LogEventLevel>(strLogLevel,true,out logLevel);

            ILogger _log = new LoggerConfiguration()
                .MinimumLevel.Is(res ? logLevel : LogEventLevel.Information)
                .WriteTo.Console()
                .CreateLogger();
            Log.Logger = _log;

            Log.Debug(String.Format("Storage account name is {0}",strStorageAccountName));

            int processId = System.Diagnostics.Process.GetCurrentProcess().Id;

            Log.Information($"Current process ID is {processId}.");

            MainAsync(_log).GetAwaiter().GetResult();

            Log.Information("Main thread exit.");
            
        }

        private static async Task MainAsync(ILogger log)
        {
            // This block is to ensure that the code can handle two stop methods: either
            // receiving a SIGTERM (how containers get told to stop, per https://github.com/dotnet/coreclr/issues/2688),
            // or a cancel key combination (Control-C or Control-Break). There wasn't a lot of docs on this, hopefully it
            // works! HT to https://stackoverflow.com/questions/53784213/gracefully-handle-aws-ecs-stop-task-with-net-core-application.
            var quitEvent = new ManualResetEvent(false);
            AssemblyLoadContext.Default.Unloading += ctx =>
            {
                Log.Information("STOP condition received. Setting shutdown flag.");
                quitEvent.Set();
            };
            Console.CancelKeyPress += (object Sender, ConsoleCancelEventArgs args) =>
            {
                Log.Information("STOP key press received. Setting shutdown flag.");
                quitEvent.Set();
                args.Cancel = true;
            };

            var MetricServer = new KestrelMetricServer(port:9090);
            MetricServer.Start();

            Log.Information("Registering EventProcessor");

            var eventProcessorHost = new EventProcessorHost(
                strEventHubName,
                PartitionReceiver.DefaultConsumerGroupName,
                strEventHubConnectionString,
                strStorageAccountConnectionString,
                strStorageContainerName
            );

            await eventProcessorHost.RegisterEventProcessorAsync<SimpleEventProcessor>();

            Log.Information("EventProcessor registered.");

            // Wait for one of the quit signals to come.
            quitEvent.WaitOne();

            Log.Information("Shutdown signal received. Un-registering EventProcessor.");
            Task shutdownTask = eventProcessorHost.UnregisterEventProcessorAsync();
            shutdownTask.Wait(-1);
            MetricServer.Stop();
            Log.Information("Shutdown complete.");
            
        }
    }
}