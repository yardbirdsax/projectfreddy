using Microsoft.Azure.EventHubs;
using Microsoft.Azure.EventHubs.Processor;
using System.Threading.Tasks;
using Serilog;
using System;
using System.Text;
using System.Collections.Generic;
using Newtonsoft.Json;
using Prometheus;

namespace iotprocessor
{
  internal class SimpleEventProcessor : IEventProcessor
  {
    #region variables
    #endregion

    #region Prometheus metrics
    static readonly Gauge CurrentTemperature = Metrics.CreateGauge(
        "current_temperature",
        "The current reported temperature for the device.",
        new GaugeConfiguration
        {
            LabelNames = new[] {"deviceName"}
        });
    #endregion
    
    public Task CloseAsync(PartitionContext context, CloseReason reason)
    {
        Log.Information($"Processor Shutting Down. Partition '{context.PartitionId}', Reason: '{reason}'.");
        return Task.CompletedTask;
    }

    public Task OpenAsync(PartitionContext context)
    {
        Log.Information($"SimpleEventProcessor initialized. Partition: '{context.PartitionId}'");
        return Task.CompletedTask;
    }

    public Task ProcessErrorAsync(PartitionContext context, Exception error)
    {
        Log.Error($"Error on Partition: {context.PartitionId}, Error: {error.Message}");
        return Task.CompletedTask;
    }

    public Task ProcessEventsAsync(PartitionContext context, IEnumerable<EventData> messages)
    {
        foreach (var eventData in messages)
        {
            string data = Encoding.UTF8.GetString(eventData.Body.Array, eventData.Body.Offset, eventData.Body.Count);
            Log.Debug($"Message received. Partition: '{context.PartitionId}', Data: '{data}'");
            Log.Debug("Deserializing data.");
            IotRecord iotRecord = JsonConvert.DeserializeObject<IotRecord>(data);
            Log.Debug($"Device Name: '{iotRecord.Device}', temp: {iotRecord.Temp.ToString()}");
            CurrentTemperature.WithLabels(iotRecord.Device).Set(iotRecord.Temp);
        }

        return context.CheckpointAsync();
    }
  }
}