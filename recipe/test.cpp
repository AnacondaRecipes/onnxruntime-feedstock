#define ORT_API_MANUAL_INIT
#include <onnxruntime/core/session/onnxruntime_cxx_api.h>
#include <array>
#include <cstdlib>
#include <iostream>

int main() {
    Ort::InitApi();
    const auto providers = Ort::GetAvailableProviders();

    for (const auto& provider : providers) {
        std::cout << provider << '\n';
    }

#ifdef ORT_TEST_CUDA
    // mul_1.onnx computes Y = X * W with W = [1..6], so X = [1..6] gives the squares.
    // CPU fallback is disabled: session creation fails unless every node runs on the CUDA EP.
    try {
        Ort::Env env(ORT_LOGGING_LEVEL_WARNING, "cuda-smoke");
        Ort::SessionOptions options;
        options.AddConfigEntry("session.disable_cpu_ep_fallback", "1");
        OrtCUDAProviderOptions cuda_options{};
        options.AppendExecutionProvider_CUDA(cuda_options);
        Ort::Session session(env, ORT_TSTR("onnxruntime/test/testdata/mul_1.onnx"), options);

        std::array<float, 6> x{1, 2, 3, 4, 5, 6};
        std::array<int64_t, 2> shape{3, 2};
        auto memory = Ort::MemoryInfo::CreateCpu(OrtArenaAllocator, OrtMemTypeDefault);
        auto input = Ort::Value::CreateTensor<float>(memory, x.data(), x.size(), shape.data(), shape.size());
        const char* inputs[] = {"X"};
        const char* outputs[] = {"Y"};
        auto result = session.Run(Ort::RunOptions{nullptr}, inputs, &input, 1, outputs, 1);
        if (result.size() != 1 || result[0].GetTensorTypeAndShapeInfo().GetElementCount() != x.size()) {
            std::cerr << "unexpected output shape\n";
            return EXIT_FAILURE;
        }
        const float* y = result[0].GetTensorData<float>();
        for (size_t i = 0; i < x.size(); ++i) {
            if (y[i] != x[i] * x[i]) {
                std::cerr << "wrong value at " << i << '\n';
                return EXIT_FAILURE;
            }
        }
        std::cout << "CUDA EP inference OK\n";
    } catch (const std::exception& e) {
        std::cerr << e.what() << '\n';
        return EXIT_FAILURE;
    }
#endif

    return EXIT_SUCCESS;
}
