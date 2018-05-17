//
//  FolioReaderContainer.swift
//  FolioReaderKit
//
//  Created by Heberti Almeida on 15/04/15.
//  Copyright (c) 2015 Folio Reader. All rights reserved.
//

import UIKit
import FontBlaster

/// Reader container
open class FolioReaderContainer: UIViewController {
    var shouldHideStatusBar = true
    var shouldRemoveEpub = true
    
    // Mark those property as public so they can accessed from other classes/subclasses.
    public var book: FRBook
    
    public var centerNavigationController: UINavigationController?
    public var centerViewController: FolioReaderCenter?
    public var audioPlayer: FolioReaderAudioPlayer?
    
    public var readerConfig: FolioReaderConfig
    public var folioReader: FolioReader

    fileprivate var errorOnLoad = false

    // MARK: - Init

    public init(config: FolioReaderConfig, folioReader: FolioReader, book: FRBook) {
        self.readerConfig = config
        self.folioReader = folioReader
        self.book = book
        
        super.init(nibName: nil, bundle: Bundle.frameworkBundle())
        
        // Configure the folio reader.
        self.folioReader.readerContainer = self
        
        self.initialization()
    }
    
    // out of... time...
    required public init?(coder aDecoder: NSCoder) {
        self.book = FRBook()
        self.readerConfig = FolioReaderConfig()
        self.folioReader = FolioReader()
        super.init(coder: aDecoder)
        assert(false)
    }

    /// Common Initialization
    fileprivate func initialization() {
        // Register custom fonts
        FontBlaster.blast(bundle: Bundle.frameworkBundle())

        // Register initial defaults
        self.folioReader.register(defaults: [
            kCurrentFontFamily: FolioReaderFont.andada.rawValue,
            kNightMode: false,
            kCurrentFontSize: 2,
            kCurrentAudioRate: 1,
            kCurrentHighlightStyle: 0,
            kCurrentTOCMenu: 0,
            kCurrentMediaOverlayStyle: MediaOverlayStyle.default.rawValue,
            kCurrentScrollDirection: FolioReaderScrollDirection.defaultVertical.rawValue
            ])
    }

    // MARK: - View life cicle

    override open func viewDidLoad() {
        super.viewDidLoad()

        let canChangeScrollDirection = self.readerConfig.canChangeScrollDirection
        self.readerConfig.canChangeScrollDirection = self.readerConfig.isDirection(canChangeScrollDirection, canChangeScrollDirection, false)

        // If user can change scroll direction use the last saved
        if self.readerConfig.canChangeScrollDirection == true {
            var scrollDirection = FolioReaderScrollDirection(rawValue: self.folioReader.currentScrollDirection) ?? .vertical
            if (scrollDirection == .defaultVertical && self.readerConfig.scrollDirection != .defaultVertical) {
                scrollDirection = self.readerConfig.scrollDirection
            }

            self.readerConfig.scrollDirection = scrollDirection
        }

        let hideBars = readerConfig.hideBars
        self.readerConfig.shouldHideNavigationOnTap = ((hideBars == true) ? true : self.readerConfig.shouldHideNavigationOnTap)

        self.centerViewController = FolioReaderCenter(withContainer: self)

        if let rootViewController = self.centerViewController {
            self.centerNavigationController = UINavigationController(rootViewController: rootViewController)
        }

        self.centerNavigationController?.setNavigationBarHidden(self.readerConfig.shouldHideNavigationOnTap, animated: false)
        if let _centerNavigationController = self.centerNavigationController {
            self.view.addSubview(_centerNavigationController.view)
            self.addChildViewController(_centerNavigationController)
        }
        self.centerNavigationController?.didMove(toParentViewController: self)
        self.centerNavigationController?.navigationBar.setBackgroundImage(UIImage.imageWithColor(color: .white), for: .default)
        self.centerNavigationController?.navigationBar.shadowImage = UIImage.imageWithColor(color: .white)
        if let bar = self.centerNavigationController?.navigationBar {
            bar.layer.borderColor = UIColor.clear.cgColor
            bar.layer.masksToBounds = false
            bar.layer.shadowColor = UIColor.black.cgColor
            bar.layer.shadowOpacity = 0.15
            bar.layer.shadowOffset = CGSize(width: 0, height: 4)
            bar.layer.shadowRadius = 4
        }

        if (self.readerConfig.hideBars == true) {
            self.readerConfig.shouldHideNavigationOnTap = false
            self.navigationController?.navigationBar.isHidden = true
            self.centerViewController?.pageIndicatorHeight = 0
        }

        self.folioReader.isReaderOpen = true

        if self.book.hasAudio || self.readerConfig.enableTTS {
            self.addAudioPlayer()
        }
        self.centerViewController?.reloadData()
        self.folioReader.isReaderReady = true
        self.folioReader.delegate?.folioReader?(self.folioReader, didFinishedLoading: self.book)
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if (self.errorOnLoad == true) {
            self.dismiss()
        }
    }

    /**
     Initialize the media player
     */
    func addAudioPlayer() {
        self.audioPlayer = FolioReaderAudioPlayer(withFolioReader: self.folioReader, book: self.book)
        self.folioReader.readerAudioPlayer = audioPlayer
    }

    // MARK: - Status Bar

    override open var prefersStatusBarHidden: Bool {
        return (self.readerConfig.shouldHideNavigationOnTap == false ? false : self.shouldHideStatusBar)
    }

    override open var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return UIStatusBarAnimation.slide
    }

    override open var preferredStatusBarStyle: UIStatusBarStyle {
        return self.folioReader.isNight(.lightContent, .default)
    }
}

extension FolioReaderContainer {
    func alert(message: String) {
        let alertController = UIAlertController(
            title: "Error",
            message: message,
            preferredStyle: UIAlertControllerStyle.alert
        )
        let action = UIAlertAction(title: "OK", style: UIAlertActionStyle.cancel) { [weak self]
            (result : UIAlertAction) -> Void in
            self?.dismiss()
        }
        alertController.addAction(action)
        self.present(alertController, animated: true, completion: nil)
    }
}
