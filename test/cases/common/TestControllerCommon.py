from cases.common.TestMainCommon import TestMainCommon
import yaml, os, re, socket, unittest, testinfra

class TestControllerCommon(TestMainCommon):

    def test_package_jq(self):
        """A package jq should be installed"""
        self.assertTrue(self.host.package("jq").is_installed)

    #def test_package_netfilter_persistent(self):
    #    """A package netfilter-persistent should be installed"""
    #    self.assertTrue(self.host.package("netfilter-persistent").is_installed)
    #    service = self.host.service("netfilter-persistent")
    #    self.assertTrue(service.is_enabled)
    #    self.assertTrue(service.is_running)

    #def test_settings_apt_cacher_ng(self):
    #    super().assert_settings_apt_cacher_ng("http://127.0.0.1:3142")

