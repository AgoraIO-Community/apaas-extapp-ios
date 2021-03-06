//
//  EMMessageModel.m
//  ChatDemo-UI3.0
//
//  Created by XieYajie on 2019/1/18.
//  Copyright © 2019 XieYajie. All rights reserved.
//

#import "EMMessageModel.h"

@implementation EMMessageModel

- (instancetype)initWithEMMessage:(AgoraChatMessage*)aMsg
{
    self = [super init];
    if (self) {
        _emModel = aMsg;
        _direction = aMsg.direction;
        if (aMsg.body.type == AgoraChatMessageBodyTypeText) {
            _type = AgoraChatMessageTypeText;
            if ([aMsg.ext objectForKey:MSG_EXT_GIF]) {
                _type = AgoraChatMessageTypeExtGif;
            } else if ([aMsg.ext objectForKey:MSG_EXT_RECALL]) {
                _type = AgoraChatMessageTypeExtRecall;
            }
            if (aMsg.isNeedGroupAck) {
                _readReceiptCount = [NSString stringWithFormat:@"阅读回执，已读用户（%d）",aMsg.groupAckCount];
            }
            if(aMsg.isNeedGroupAck  && aMsg.status == AgoraChatMessageStatusFailed) {
                _readReceiptCount = @"只有群主支持本格式消息";
            }
        } else {
            _type = (AgoraChatMessageType)aMsg.body.type;
        }
    }
    
    return self;
}

@end
