// Copyright (C) 2019 Intel Corporation
// SPDX-License-Identifier: Apache-2.0
//

/**
 * @brief a header file with ouput classification results
 * @file classification_results.hpp
 */
#include <string>
#include <vector>
#include <iostream>
#include <utility>

#include <ie_blob.h>

/**
 * @class ClassificationResult
 * @brief A ClassificationResult creates an output table with results
 */
class ClassificationResult {
private:
    const std::string _classidStr = "classid";
    const std::string _probabilityStr = "probability";
    const std::string _labelStr = "label";
    size_t _nTop;
    InferenceEngine::Blob::Ptr _outBlob;
    const std::vector<std::string> _labels;
    const std::vector<std::string> _imageNames;
    const size_t _batchSize;

    void printHeader() {
        slog::info  << _classidStr << " " << _probabilityStr;
        if (!_labels.empty())
            slog::info  << " " << _labelStr;
        std::string classidColumn(_classidStr.length(), '-');
        std::string probabilityColumn(_probabilityStr.length(), '-');
        std::string labelColumn(_labelStr.length(), '-');
        slog::info << slog::endl << classidColumn << " " << probabilityColumn;
        if (!_labels.empty())
            slog::info << " " << labelColumn;
        slog::info << slog::endl;
    }

public:
    explicit ClassificationResult(InferenceEngine::Blob::Ptr output_blob,
                                  std::vector<std::string> image_names = {},
                                  size_t batch_size = 1,
                                  size_t num_of_top = 10,
                                  std::vector<std::string> labels = {}) :
            _nTop(num_of_top),
            _outBlob(std::move(output_blob)),
            _labels(std::move(labels)),
            _imageNames(std::move(image_names)),
            _batchSize(batch_size) {
        if (_imageNames.size() != _batchSize) {
            throw std::logic_error("Batch size should be equal to the number of images.");
        }
    }

    /**
    * @brief prints formatted classification results
    */
    void print() {
        /** This vector stores id's of top N results **/
        std::vector<unsigned> results;
        TopResults(_nTop, *_outBlob, results);

        /** Print the result iterating over each batch **/
        slog::info << slog::endl << "Top " << _nTop << " results:" << slog::endl << slog::endl;
        for (unsigned int image_id = 0; image_id < _batchSize; ++image_id) {
            slog::info << "Image " << _imageNames[image_id] << slog::endl << slog::endl;
            printHeader();

            for (size_t id = image_id * _nTop, cnt = 0; id < (image_id + 1) * _nTop; ++cnt, ++id) {
                //slog::info.precision(7);
                /** Getting probability for resulting class **/
                const auto result = _outBlob->buffer().
                        as<InferenceEngine::PrecisionTrait<InferenceEngine::Precision::FP32>::value_type*>()
                [results[id] + image_id * (_outBlob->size() / _batchSize)];

                slog::info << std::setw(static_cast<int>(_classidStr.length())) << std::left << results[id] << " ";
                slog::info << std::left << std::setw(static_cast<int>(_probabilityStr.length())) << std::fixed << result;

                if (!_labels.empty()) {
                    slog::info << " " + _labels[results[id]];
                }
                slog::info << slog::endl;
            }
            slog::info << slog::endl;
        }
    }
};
