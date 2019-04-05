//
//  LocalBonjourController.swift
//  CryptoExercise
//
//  Translated by OOPer in cooperation with shlab.jp, on 2015/4/19.
//
//
/*

 File: LocalBonjourController.h
 File: LocalBonjourController.m
 Abstract: Handles all of the Bonjour initialization code and back-end to the
 UIScrollView for browsing network service instances of this sample.

 Version: 1.2

 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple Inc.
 ("Apple") in consideration of your agreement to the following terms, and your
 use, installation, modification or redistribution of this Apple software
 constitutes acceptance of these terms.  If you do not agree with these terms,
 please do not use, install, modify or redistribute this Apple software.

 In consideration of your agreement to abide by the following terms, and subject
 to these terms, Apple grants you a personal, non-exclusive license, under
 Apple's copyrights in this original Apple software (the "Apple Software"), to
 use, reproduce, modify and redistribute the Apple Software, with or without
 modifications, in source and/or binary forms; provided that if you redistribute
 the Apple Software in its entirety and without modifications, you must retain
 this notice and the following text and disclaimers in all such redistributions
 of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may be used
 to endorse or promote products derived from the Apple Software without specific
 prior written permission from Apple.  Except as expressly stated in this notice,
 no other rights or licenses, express or implied, are granted by Apple herein,
 including but not limited to any patent rights that may be infringed by your
 derivative works or by other works in which the Apple Software may be
 incorporated.

 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
 WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
 WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
 COMBINATION WITH YOUR PRODUCTS.

 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
 CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
 GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
 ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR
 DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF
 CONTRACT, TORT (INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF
 APPLE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

 Copyright (C) 2008-2009 Apple Inc. All Rights Reserved.

 */

import UIKit


@objc(LocalBonjourController)
class LocalBonjourController: UIViewController, NetServiceBrowserDelegate, UITableViewDataSource, UITableViewDelegate {
    
    var netServiceBrowser: NetServiceBrowser?
    var services: [NetService] = []
    @IBOutlet var tableView: UITableView!
    private lazy var _serviceController: ServiceController = ServiceController(nibName: "ServiceView", bundle: nil)
    var serviceController: ServiceController {
        get { return _serviceController }
        set { _serviceController = newValue }
    }
    private lazy var _keyGenerationController: KeyGeneration = KeyGeneration(nibName: "KeyGeneration", bundle: nil)
    var keyGenerationController: KeyGeneration {
        get { return _keyGenerationController }
        set { _keyGenerationController = newValue }
    }
    var cryptoServer: CryptoServer!
    
    override func viewDidLoad() {
        self.services = []
        
        // Check to see if keys have been generated.
        if SecKeyWrapper.shared.getPublicKeyRef() == nil ||
            SecKeyWrapper.shared.getPrivateKeyRef() == nil ||
            SecKeyWrapper.shared.getSymmetricKeyBytes() == nil {
                
                SecKeyWrapper.shared.generateKeyPair(kAsymmetricSecKeyPairModulusSize)
                SecKeyWrapper.shared.generateSymmetricKey()
        }
        
        let thisServer = CryptoServer()
        self.cryptoServer = thisServer
        self.cryptoServer.run()
    }
    
    @IBAction func regenerateKeys() {
        let controller = self.keyGenerationController
        controller.server = cryptoServer
        self.navigationController?.present(controller, animated: true, completion: nil)
    }
    
    override var shouldAutorotate: Bool {
        return false
    }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        // Return YES for supported orientations
        return UIInterfaceOrientationMask.portrait
    }
    
    // Creates an NSNetServiceBrowser that searches for services of a particular type in a particular domain.
    // If a service is currently being resolved, stop resolving it and stop the service browser from
    // discovering other services.
    @discardableResult
    func searchForCryptoServices() -> Bool {
        self.netServiceBrowser?.stop()
        self.services.removeAll()
        tableView.reloadData()
        
        let aNetServiceBrowser = NetServiceBrowser()
        aNetServiceBrowser.delegate = self
        self.netServiceBrowser = aNetServiceBrowser
        
        self.netServiceBrowser!.searchForServices(ofType: kBonjourServiceType, inDomain: "local")
        
        return true
    }
    
    func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        if let index = self.services.firstIndex(of: service) {self.services.remove(at: index)}
        if !moreComing { tableView.reloadData() }
    }

    func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        
        #if ALLOW_TO_CONNECT_TO_SELF
            self.services.append(service)
        #else
            // Don't display our published record
            if cryptoServer.netService?.name != service.name {
                // If a service came online, add it to the list and update the table view if no more events are queued.
                self.services.append(service)
            
            }
        #endif
        
        if !moreComing {
            tableView.reloadData()
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return services.count
    }
    
    func tableView(_ tv: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "MyCell") as UITableViewCell?
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "MyCell")
        }
        cell!.textLabel!.text = services[indexPath.row].name
        cell!.accessoryType = .disclosureIndicator
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.serviceController.service = self.services[indexPath.row]
        self.navigationController?.pushViewController(self.serviceController, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        self.searchForCryptoServices()
    }
    
    
    
}
