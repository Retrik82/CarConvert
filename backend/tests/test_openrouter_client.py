from app.services.ai.openrouter_client import _extract_image_reference


def test_extract_image_reference_from_message_images() -> None:
    payload = {
        "choices": [
            {
                "message": {
                    "role": "assistant",
                    "content": "Here is your image.",
                    "images": [
                        {
                            "image_url": {
                                "url": "data:image/png;base64,abc123",
                            }
                        }
                    ],
                }
            }
        ]
    }

    assert _extract_image_reference(payload) == "data:image/png;base64,abc123"
