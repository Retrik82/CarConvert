"""Tests for pose-to-angle mapping."""

from app.services.pose_to_angle import map_pose_to_catalog_angle


def test_map_three_quarter_left():
    assert map_pose_to_catalog_angle({"view_family": "three_quarter", "facing": "front_left"}) == "three_quarter_left"


def test_map_profile_left():
    assert map_pose_to_catalog_angle({"view_family": "profile", "facing": "left"}) == "left"


def test_map_interior():
    assert map_pose_to_catalog_angle({"view_family": "interior"}) == "interior"


def test_map_direct_angle():
    assert map_pose_to_catalog_angle({"angle": "rear"}) == "rear"


def test_map_default():
    assert map_pose_to_catalog_angle({}) == "three_quarter_left"
