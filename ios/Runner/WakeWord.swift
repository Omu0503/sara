import TensorFlowLite

class WakeWordDetector {
    private var interpreter: Interpreter?
    private let modelInputShape = [1, 16, 96] // Model's expected input shape
    private let modelInputSize: Int
    private let channel: FlutterMethodChannel

    init(channel: FlutterMethodChannel) {
        self.channel = channel
        guard let modelPath = Bundle.main.path(forResource: "Saraa", ofType: "tflite") else {
            fatalError("Failed to load the model file.")
        }

        do {
            interpreter = try Interpreter(modelPath: modelPath)
            try interpreter?.allocateTensors() // Allocate tensors here

            let inputShape = try interpreter?.input(at: 0).shape
            modelInputSize =  16*96 // Flatten the shape to get total input size
            NSLog("WakeWordDetector initialized with model at path: \(modelPath)")
            NSLog("Model input shape: \(String(describing: inputShape))")
        } catch {
            fatalError("Failed to create interpreter: \(error.localizedDescription)")
        }
    }

    func detectWakeWord(audioData: [Float]) -> Bool {
            guard let interpreter = interpreter else {
                fatalError("Interpreter not initialized.")
            }

            // Prepare input buffer
            let inputBuffer = prepareInputBuffer(audioData: audioData)
        print(inputBuffer)

            do {
                // Copy input data to the input tensor
                try interpreter.copy(inputBuffer, toInputAt: 0)
                // Run inference
                try interpreter.invoke()

                // Get output data from the output tensor
                let outputTensor = try interpreter.output(at: 0)
                let outputSize = outputTensor.shape.dimensions.reduce(1, *)
                print("Ouput Size: \(outputSize)")
                let outputBuffer = [Float32](unsafeUninitializedCapacity: outputSize) { buffer, initializedCount in
                    outputTensor.data.copyBytes(to: buffer, count: outputTensor.data.count)
                    initializedCount = outputSize
                }
                let maxVal = outputBuffer.max() ?? 0
                
                let prediction = outputBuffer.first ?? 0.0
                
                print("Prediction: \(String(format: "%.3f", prediction))")
                
                channel.invokeMethod("logPrediction", arguments: String(format: "%.3f", prediction))
                
                
                return prediction > 0.6 // Adjust threshold as necessary
            } catch {
                fatalError("Failed to run interpreter: \(error.localizedDescription)")
            }
        }

    private func prepareInputBuffer(audioData: [Float]) -> Data {
            // Normalize audio data to [-1.0, 1.0]
        
//            let normalizedAudioData = audioData.map { $0 / 32767.0 }

            // Create input buffer
            var inputBuffer = Data(count: modelInputSize * MemoryLayout<Float>.size)
            for i in 0..<modelInputSize {
                let value = i < audioData.count ? audioData[i] : 0.0
                withUnsafeBytes(of: value) { valuePtr in
                    inputBuffer.replaceSubrange(i * MemoryLayout<Float>.size..<((i + 1) * MemoryLayout<Float>.size), with: valuePtr)
                }
            }
            return inputBuffer
        }
    func cleanup() {
        NSLog("Cleaning up WakeWordDetector")
        interpreter = nil
    }
}

extension Array where Element == Float32 {
    init(unsafeData: Data) {
        let buffer = unsafeData.withUnsafeBytes {
            UnsafeBufferPointer<Float32>(
                start: $0.baseAddress!.assumingMemoryBound(to: Float32.self),
                count: unsafeData.count / MemoryLayout<Float32>.stride
            )
        }
        self = Array(buffer)
    }
}
