import requests

# URL of the Flask API
BASE_URL = 'http://192.168.131.199:5000'

# Function to test uploading an image
def test_upload_image():
    url = f"{BASE_URL}/upload_image"
    # Define the image file path (use an existing image file on your system)
    image_path = r"C:\Users\mukes\OneDrive\Documents\GenAI x Gender Tech Hackathon\YOLO_traffic\images.jpeg"

    # Prepare the data to send in the request
    data = {
        'latitude': '12.9716',  # Example latitude (e.g., for Bangalore)
        'longitude': '77.5946',  # Example longitude
        'time': '2025-01-16T12:00:00'  # Example timestamp
    }

    files = {
        'file': open(image_path, 'rb')  # Open the image file in binary mode
    }

    # Send the POST request
    response = requests.post(url, data=data, files=files)

    # Check the response
    if response.status_code == 200:
        print("Image uploaded successfully:", response.json())
    else:
        print(f"Failed to upload image: {response.status_code}, {response.json()}")

    # Close the file
    files['file'].close()

# Function to test fetching safety data
def test_get_safety_data():
    url = f"{BASE_URL}/get_safety_data"

    # Send the GET request to fetch the stored safety data
    response = requests.get(url)

    # Check the response
    if response.status_code == 200:
        print("Safety data fetched successfully:", response.json())
    else:
        print(f"Failed to fetch safety data: {response.status_code}, {response.json()}")

# Run the tests
if __name__ == '__main__':
    test_upload_image()  # Test image upload
    test_get_safety_data()  # Test fetching safety data
