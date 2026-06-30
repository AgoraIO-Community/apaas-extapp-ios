//
//  FcrCloudDriveWidget.swift
//  AgoraWidgets
//
//  Created by ZYP on 2021/10/20.
//

import MobileCoreServices
import AgoraWidget
import AgoraFoundation

import Photos
import Darwin

@objcMembers public class FcrCloudDriveWidget: AgoraNativeWidget,
                                               AgoraUIContentContainer {
    private let contentView = FcrCloudDriveView(frame: .zero)
    private var dataSource = FcrCloudDriveDataSource()
    private var serverAPI: FcrCloudDriveServerAPI?
    
    private var selectedIndex: IndexPath?
    private var isUpdatingConverting = false
    
    private var uploadFileCount = 0 {
        didSet {
            contentView.bottomView.uploadFileButton.cusState = ((uploadFileCount == 0) ? .normal : .uploading)
        }
    }
    
    private var uploadImageCount = 0 {
        didSet {
            contentView.bottomView.uploadImageButton.cusState = ((uploadFileCount == 0) ? .normal : .uploading)
        }
    }
    
    public override func onLoad() {
        super.onLoad()
        initViews()
        initViewFrame()
        updateViewProperties()
        
        createPublicDataSource()
        dataSource.filterFileList(with: .uiPublic)
        contentView.listView.reloadData()
    }
    
    public override func onMessageReceived(_ message: String) {
        guard let keys = message.toRequestKeys() else {
            return
        }
        
        serverAPI = FcrCloudDriveServerAPI(host: keys.host,
                                           appId: keys.agoraAppId,
                                           token: keys.token,
                                           roomId: info.roomInfo.roomUuid,
                                           userId: info.localUserInfo.userUuid,
                                           logTube: self.logger)
        
        createPrivateDataSource { [weak self] _ in
            guard let contentView = self?.contentView else {
                return
            }
            
            guard contentView.topView.selectedType == .uiPrivate else {
                return
            }
            
            contentView.listView.reloadData()
        }
    }
    
    public func initViews() {
        view.backgroundColor = .clear
        view.addSubview(contentView)
        
        contentView.topView.delegate = self
        contentView.listView.dataSource = self
        contentView.listView.delegate = self
        
        contentView.topView.updateFileCount(dataSource.filteredFileList.count)
        
        contentView.bottomView.uploadFileButton.addTarget(self,
                                                          action: #selector(onUploadFileButtonPressed),
                                                          for: .touchUpInside)
        
        contentView.bottomView.uploadImageButton.addTarget(self,
                                                           action: #selector(onUploadImageButtonPressed),
                                                           for: .touchUpInside)
        
        contentView.bottomView.deleteButton.addTarget(self,
                                                      action: #selector(onDeleteButtonPressed),
                                                      for: .touchUpInside)
    }
    
    public func initViewFrame() {
        contentView.agora_mas_makeConstraints { make in
            make?.left.right().top().bottom().equalTo()(self.view)
        }
    }
    
    public func updateViewProperties() {
        let config = UIConfig.cloudStorage
        
        view.layer.shadowColor = config.shadow.color
        view.layer.shadowOffset = config.shadow.offset
        view.layer.shadowOpacity = config.shadow.opacity
        view.layer.shadowRadius = config.shadow.radius
    }
}

// MARK: - Data
private extension FcrCloudDriveWidget {
    func createPublicDataSource() {
        guard let extraInfo = ValueTransform(value: info.extraInfo,
                                             result: [String: Any].self),
              let jsonArray = ValueTransform(value: extraInfo["publicCoursewares"],
                                             result: [String].self)
        else {
            return
        }
        
        dataSource.createPublicFileList(with: jsonArray)
    }
    
    func createPrivateDataSource(success: ((Bool) -> ())? = nil,
                                 failure: ((Error) -> ())? = nil) {
        fetchPrivateFileList { [weak self] object in
            guard let `self` = self else {
                return
            }
            
            let hasConvertingFiles = self.dataSource.createPrivateFileList(with: object.list)
            success?(hasConvertingFiles)
        } failure: { error in
            failure?(error)
        }
    }
    
    func fetchPrivateFileList(resourceName: String? = nil,
                              success: ((FcrCloudDriveFileListServerObject) -> ())?,
                              failure: ((Error) -> ())?) {
        guard let `serverApi` = serverAPI else {
            return
        }
        
        serverApi.requestResourceInUser(pageNo: 1,
                                        pageSize: 100,
                                        resourceName: resourceName) { [weak self] (object) in
            success?(object)
        } failure: { [weak self](error) in
            failure?(error)
        }
    }
    
    func updateConvertingOfFileList() {
        isUpdatingConverting = true
        
        createPrivateDataSource { [weak self] hasConvertingFiles in
            guard let `self` = self else {
                return
            }
            
            if hasConvertingFiles {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                    self?.updateConvertingOfFileList()
                }
            } else {
                self.isUpdatingConverting = false
            }
            
            self.dataSource.filterFileList(with: .uiPrivate)
            self.contentView.topView.updateFileCount(self.dataSource.filteredFileList.count)
            self.contentView.listView.reloadData()
        } failure: { [weak self] _ in
            self?.updateConvertingOfFileList()
        }
    }
}

// MARK: - FcrCloudDriveTopViewDelegate
extension FcrCloudDriveWidget: FcrCloudDriveTopViewDelegate {
    func onTypeButtonPressed(type: FcrCloudDriveFileViewType) {
        dataSource.filterFileList(with: type,
                                  keyWords: contentView.topView.searchBar.text)
        
        contentView.topView.updateFileCount(dataSource.filteredFileList.count)
        
        contentView.listView.reloadData()
        
        contentView.hideBottomView((type == .uiPublic))
    }
    
    func onCloseButtonPressed() {
        sendCloseMessage()
    }
    
    func onRefreshButtonPressed() {
        contentView.bottomView.state = .upload
        contentView.listView.reloadData()
        
        guard contentView.topView.selectedType == .uiPrivate else {
            return
        }
        
        createPrivateDataSource { [weak self] _ in
            self?.contentView.listView.reloadData()
        }
    }
    
    func onSearched(content: String) {
        dataSource.filterFileList(with: contentView.topView.selectedType,
                                  keyWords: content)
        
        contentView.topView.updateFileCount(dataSource.filteredFileList.count)
        
        contentView.listView.reloadData()
    }
}

// MARK: - UITableViewDataSource, UITableViewDelegate
extension FcrCloudDriveWidget: UITableViewDataSource,
                               UITableViewDelegate,
                               FcrCloudDriveCellDelegate {
    public func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
        return dataSource.filteredFileList.count
    }
    
    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: FcrCloudDriveCell.cellId,
                                                 for: indexPath) as! FcrCloudDriveCell
        
        let data = dataSource.filteredFileList[indexPath.row].viewData
        cell.iconImageView.image = data.image
        cell.nameLabel.text = data.name
        cell.index = indexPath
        cell.showType = data.state
        cell.delegate = self
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView,
                          didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath,
                              animated: true)
        
        let data = dataSource.filteredFileList[indexPath.row].originalData
        
        sendSelectedFileMessage(data: data)
    }
    
    // Cell
    func onSelected(_ index: IndexPath) {
        if let last = selectedIndex,
            last == index {
            contentView.bottomView.state = .upload
            selectedIndex = nil
            
            dataSource.updatePrivateFileListToSelectableState()
            dataSource.filterFileList(with: .uiPrivate)
            contentView.topView.updateFileCount(dataSource.filteredFileList.count)
            contentView.listView.reloadData()
        } else {
            contentView.bottomView.state = .delete
            selectedIndex = index
            
            dataSource.updateItemOfPrivateFileList(selectedState: index.row)
            dataSource.filterFileList(with: .uiPrivate)
            contentView.topView.updateFileCount(dataSource.filteredFileList.count)
            contentView.listView.reloadData()
        }
    }
}

private extension FcrCloudDriveWidget {
    @objc func onUploadFileButtonPressed() {
        let documentPicker = UIDocumentPickerViewController(documentTypes: ["public.content"],
                                                            in: .import)
        documentPicker.delegate = self
        
        guard let vc = UIViewController.agora_top_view_controller() else {
            return
        }
        
        vc.present(documentPicker,
                   animated: true)
    }
    
    @objc func onUploadImageButtonPressed() {
        guard let vc = UIViewController.agora_top_view_controller() else {
            return
        }
        
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [String(kUTTypeImage)]
        
        vc.present(imagePicker,
                   animated: true)
    }
    
    @objc func onDeleteButtonPressed() {
        guard let index = selectedIndex else {
            return
        }
        
        let cancel = AgoraAlertAction(title: "fcr_cloud_tips_delete_confirm_cancel_text".widgets_localized())
        let delete = AgoraAlertAction(title: "fcr_cloud_tips_delete_confirm_ok_text".widgets_localized()) { [weak self] _ in
            self?.deleteFile(index)
        }
        
        showAlert(title: "fcr_cloud_tips_delete_confirm_title".widgets_localized(),
                  contentList: ["fcr_cloud_tips_delete_confirm_content".widgets_localized()],
                  actions: [cancel,
                            delete])
    }
}

extension FcrCloudDriveWidget: UIDocumentPickerDelegate,
                               UIImagePickerControllerDelegate,
                               UINavigationControllerDelegate {
    public func documentPicker(_ controller: UIDocumentPickerViewController,
                               didPickDocumentsAt urls: [URL]) {
        guard let url = urls.first else {
            return
        }
        
        controller.dismiss(animated: true)
        
        uploadFileCount += 1
        
        uploadFile(url: url) { [weak self] in
            self?.uploadFileCount -= 1
        } failure: { [weak self] _ in
            self?.uploadFileCount -= 1
        }
    }
    
    public func imagePickerController(_ picker: UIImagePickerController,
                                      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard #available(iOS 11.0, *) else {
            picker.dismiss(animated: true)
            showToast("os version is too low")
            return
        }
        
        guard let url = info[.imageURL] as? URL else {
            return
        }
        
        picker.dismiss(animated: true)
        
        uploadImageCount += 1
        
        uploadFile(url: url) { [weak self] in
            self?.uploadImageCount -= 1
        } failure: { [weak self] _ in
            self?.uploadImageCount -= 1
        }
    }
    
    func uploadFile(url: URL,
                    success: @escaping SuccessCompletion,
                    failure: @escaping FailureCompletion) {
        serverAPI?.uploadResourceInUser(fileURL: url,
                                        success: { [weak self] in
            guard let `self` = self else {
                return
            }
            
            guard !self.isUpdatingConverting else {
                return
            }
            
            success()
            
            self.updateConvertingOfFileList()
        }, failure: { [weak self] error in
            self?.log(content: "upload file unsuccessfully",
                      type: .error)
            
            failure(error)
        })
    }
    
    func deleteFile(_ index: IndexPath) {
        let item = dataSource.privateFileList[index.row]
        
        let uuid = item.originalData.resourceUuid
        
        serverAPI?.deleteResourceInUser(resourceUuid: uuid,
                                        success: { [weak self] _ in
            self?.removeFile(type: .uiPrivate,
                             index: index)
        }, failure: { [weak self] error in
            self?.removeFile(type: .uiPrivate,
                             index: index)
            
            // TODO: 删除失败的文案
            self?.showToast(error.localizedDescription,
                            type: .error)
        })
    }
    
    func removeFile(type: FcrCloudDriveFileViewType,
                    index: IndexPath) {
        dataSource.removeItemOfFileList(type: type,
                                        index: index.row)
        dataSource.updatePrivateFileListToSelectableState()
        
        dataSource.filterFileList(with: type)
        
        contentView.topView.updateFileCount(dataSource.filteredFileList.count)
        
        contentView.bottomView.state = .upload
        
        contentView.listView.reloadData()
        
        selectedIndex = nil
    }
}

// MARK: - private
private extension FcrCloudDriveWidget {
    func sendSelectedFileMessage(data: FcrCloudDriveFile) {
        guard let dictionary = data.toDictionary() else {
            return
        }
        
        var json = ["selectedFile": dictionary]
        
        guard let jsonString = json.jsonString() else {
            return
        }
        
        sendMessage(jsonString)
    }
    
    func sendCloseMessage() {
        var json = ["close": true]
        
        guard let jsonString = json.jsonString() else {
            return
        }
        
        sendMessage(jsonString)
    }
}
