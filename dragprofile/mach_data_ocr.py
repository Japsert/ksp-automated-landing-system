# Python script that:
# 1. Gets an input video
# 2. Reads the Mach number and Cd*A from each frame
# 3. Adds data to drag_profile.csv if not already there

import os
import re
import sys

import cv2
from PIL import Image
from tesserocr import PyTessBaseAPI
from tqdm import tqdm

# AeroGUI top left corner coordinates
(x, y) = (1276, 241)
MACH_COORDS = (x + 3, y + 110, x + 95, y + 138)
CDA_COORDS = (x + 3, y + 561, x + 135, y + 589)
TESSDATA_PATH = "C:/Users/Jasper/AppData/Local/Programs/Tesseract-OCR/tessdata"
MACH_REGEX = r"Mach: (\d+\.\d{3})"
CDA_REGEX = r"Cd \* S: (\d+\.\d{3}) m.{1,2}"
DRAG_PROFILE_PATH = "drag_profile.csv"


def main(filepath: str):
    """Adds data read from input video at `filepath` to drag profile.

    :param str filepath: File path of the input video.
    """

    # If file is invalid, exit
    if not os.path.isfile(filepath):
        print("Invalid file path.")
        return

    cap = cv2.VideoCapture(filepath)
    total_frames = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))

    # List of frames (tuples of Mach and Cd*A)
    frames = []
    frames_pbar = tqdm(desc="Cropping frames", unit=" frames", total=total_frames, leave=False)

    # Read video. For each frame, crop to ROI and add to list
    while cap.isOpened():
        ret, frame = cap.read()
        if not ret:
            break
        gray_frame = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
        (mx1, my1, mx2, my2) = MACH_COORDS
        (cx1, cy1, cx2, cy2) = CDA_COORDS
        mach_roi = gray_frame[my1:my2, mx1:mx2]
        cda_roi = gray_frame[cy1:cy2, cx1:cx2]
        cropped_frame = (mach_roi, cda_roi)
        frames.append(cropped_frame)
        frames_pbar.update(1)
    cap.release()
    frames_pbar.close()

    data_to_add = []
    write_count = 0
    duplicate_count = 0
    skip_count = 0

    # For each frame, OCR Mach and Cd*A. Add to drag_profile.csv,
    # if not already there
    with PyTessBaseAPI(path=TESSDATA_PATH) as api:
        for frame in tqdm(iterable=frames, desc="Reading values", unit=" frames", leave=False):
            (raw_mach, raw_cda) = frame
            # OCR Mach value
            api.SetImage(Image.fromarray(raw_mach))
            raw_mach = api.GetUTF8Text().strip()
            try:
                mach = float(re.search(MACH_REGEX, raw_mach).group(1))
            except AttributeError:
                # print(
                #    "OCR failed, skipping frame." + f"Mach: {raw_mach}, Cd*A: {raw_cda}"
                # )
                skip_count += 1
                continue

            # Check if Mach value is already in data to add or drag profile
            if any(mach == data[0] for data in data_to_add):
                duplicate_count += 1
                continue

            # OCR Cd*A value
            api.SetImage(Image.fromarray(raw_cda))
            raw_cda = api.GetUTF8Text().strip()
            try:
                cda = float(re.search(CDA_REGEX, raw_cda).group(1))
            except AttributeError:
                # print(
                #    "OCR failed, skipping frame." + f"Mach: {raw_mach}, Cd*A: {raw_cda}"
                # )
                skip_count += 1
                continue

            data_to_add.append((mach, cda))

    # Add to drag profile
    with open(DRAG_PROFILE_PATH, "a") as f:
        f.write("---\n") # run start marker
        for mach, cda in tqdm(
            data_to_add, desc="Adding to drag profile", unit=" values", leave=False
        ):
            f.write(f"{mach},{cda}\n")
            write_count += 1

    print(
        f"Done! Added {write_count} new values, skipped {duplicate_count}"
        + f" duplicate values, and skipped {skip_count} frames."
    )


try:
    filepath = sys.argv[1]
    main(filepath)
except IndexError:
    print("Please provide a file path to a video file as an argument.")
