//
//  AgoraRtmIMSendBar.swift
//  AgoraWidgets
//
//  Created by Jonathan on 2021/12/16.
//

import UIKit

protocol AgoraRtmIMSendBarDelegate: NSObjectProtocol {
    
    func onClickInputMessage()
    
    func onClickInputEmoji()
}

class AgoraRtmIMSendBar: UIView {
    
    weak var delegate: AgoraRtmIMSendBarDelegate?
    
    private var topLine: UIView!
    
    private var infoLabel: UILabel!
    
//    private var sendButton: UIButton!

    override init(frame: CGRect) {
        super.init(frame: frame)
        
        createViews()
        createConstraint()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func isMute(_ isMute: Bool) {
        if isMute {
            infoLabel.text = "fcr_rtm_im_silence_holder".agora_localized("AgoraWidgets")
        } else {
            infoLabel.text = "fcr_rtm_im_input_placeholder".agora_localized("AgoraWidgets")
        }
        
        isUserInteractionEnabled = !isMute
    }
}
// MARK: - Actions
private extension AgoraRtmIMSendBar {
    
    @objc func onClickSendMessage() {
        self.delegate?.onClickInputMessage()
    }
    
    @objc func onClickSendEmoji(_ sender: UIButton) {
        self.delegate?.onClickInputEmoji()
    }
}
// MARK: - Creations
private extension AgoraRtmIMSendBar {
    func createViews() {
        backgroundColor = UIColor(hex: 0xF9F9FC)
        
        topLine = UIView()
        topLine.backgroundColor = UIColor(hex: 0xECECF1)
        addSubview(topLine)
        
        let tap = UITapGestureRecognizer.init(target: self,
                                              action: #selector(onClickSendMessage))
        self.addGestureRecognizer(tap)
        
        infoLabel = UILabel()
        infoLabel.font = UIFont.systemFont(ofSize: 13)
        infoLabel.textColor = UIColor(hex: 0x7D8798)
        infoLabel.text = "fcr_rtm_im_input_placeholder".agora_localized("AgoraWidgets")
        addSubview(infoLabel)
        
//        sendButton = UIButton(type: .custom)
//        sendButton.setTitleColor(.white,
//                                 for: .normal)
//        sendButton.clipsToBounds = true
//        sendButton.layer.cornerRadius = 15
//        sendButton.setTitle("fcr_rtm_im_send".ag_localizedIn("AgoraWidgets"),
//                            for: .normal)
//        sendButton.titleLabel?.font = .systemFont(ofSize: 14)
//        sendButton.backgroundColor = UIColor(hex: 0x357BF6)
//        sendButton.addTarget(self,
//                             action: #selector(onClickSendMessage),
//                             for: .touchUpInside)
//        addSubview(sendButton)
    }
    
    func createConstraint() {
        topLine.mas_makeConstraints { make in
            make?.left.right().top().equalTo()(0)
            make?.height.equalTo()(1)
        }
//        sendButton.mas_makeConstraints { make in
//            make?.top.equalTo()(self)?.offset()(2)
//            make?.bottom.equalTo()(self)?.offset()(-2)
//            make?.width.equalTo()(80)
//            make?.right.equalTo()(-2)
//        }
        infoLabel.mas_makeConstraints { make in
            make?.centerX.equalTo()(0)
            make?.centerY.equalTo()(0)
        }
    }
}
