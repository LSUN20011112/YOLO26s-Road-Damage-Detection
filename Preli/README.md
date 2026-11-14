# Preliminary Image Processing

This directory contains the reproducible midterm image-processing work that preceded YOLO26s training. It preserves the small set of source examples, selected outputs, comparison figures, notebook, and final preliminary report without including duplicate QA renders or packaging archives.

## Processing stages

### Edge detection

`ED/Edge.jpg` is converted to grayscale, smoothed with a Gaussian filter, processed with Canny thresholds of 50 and 150, and closed morphologically with a 3 x 3 kernel. The notebook exports both the binary edge map and a red edge overlay.

### Point processing

`PP/gamma.jpg` is evaluated with gamma values 1.4, 1.8, 2.2, and 2.6. Gamma 2.2 is selected using visual inspection together with mean-brightness and clipped-highlight measurements.

### Spatial filtering

`SF/sharpen.jpg` is sharpened using an unsharp mask with amount 1.0. The two denoising examples are compared with median kernel sizes 3, 5, 7, and 9. A 9 x 9 median filter followed by bilateral filtering (`d=7`, `sigmaColor=35`, `sigmaSpace=35`) is selected.

### Histogram processing

The selected sharpened and denoised results are placed in `HP/`. CLAHE is applied only to the LAB luminance channel using a clip limit of 2.0 and an 8 x 8 tile grid, preserving color information while improving local contrast.

## Directory contents

```text
Preli/
|-- Preliminary_Image_Processing.ipynb
|-- ED/                 # edge-detection source image
|-- PP/                 # gamma-correction source image
|-- SF/                 # sharpening and denoising source images
|-- HP/                 # selected SF outputs used as CLAHE inputs
|-- outputs/            # reproducible selected processing outputs
|-- figures/            # trial grids and report comparison figures
`-- docs/
    `-- Preliminary_Image_Processing_Report.pdf
```

## Reproduce locally

1. Install the packages from the repository-level `requirements.txt`.
2. Start Jupyter from the repository root or from this directory.
3. Open `Preliminary_Image_Processing.ipynb`.
4. Run all cells in order.

The notebook locates a `Preli` directory automatically and overwrites the files under `outputs/` reproducibly.

## Reproduce in Google Colab

Upload the complete `Preli` directory to `/content/Preli`, or place it at `MyDrive/DIP/Project/Preli`. If a different Drive location is used, change `COLAB_PRELI_DIR` in the setup cell.

## Relationship to the detection dataset

Selected processed images from this stage replaced their corresponding source images during construction of the cleaned dataset used for YOLO26s training. Since no controlled YOLO baseline was trained on the unmodified dataset, these files document the preprocessing workflow but are not presented as proof of an accuracy improvement.
