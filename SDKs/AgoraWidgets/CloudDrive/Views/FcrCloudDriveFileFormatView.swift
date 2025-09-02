//
//  FcrCloudDriveFileFormatView.swift
//  AgoraWidgets
//
//  Created by Cavan on 2023/10/20.
//

import AgoraUIBaseViews


fileprivate enum FileType: CaseIterable {
    case ppt, word, pdf, video, audio, photo, sharingCourseware
    
    var image: UIImage? {
        switch self {
        case .ppt:                return UIImage.widgets_image("fcr_ppt")
        case .word:               return UIImage.widgets_image("fcr_doc")
        case .pdf:                return UIImage.widgets_image("fcr_pdf")
        case .video:              return UIImage.widgets_image("fcr_file_video")
        case .audio:              return UIImage.widgets_image("fcr_file_audio")
        case .photo:              return UIImage.widgets_image("fcr_file_photo")
        case .sharingCourseware:  return UIImage.widgets_image("fcr_alf")
        }
    }
    
    var title: String {
        switch self {
        case .ppt:                return "PPT"
        case .word:               return "Word"
        case .pdf:                return "Pdf"
        case .video:              return "Video"
        case .audio:              return "Audio"
        case .photo:              return "Photo"
        case .sharingCourseware:  return "Sharing courseware"
        }
    }
    
    var formatText: String {
        return "fcr_cloud_label_format".widgets_localized() + ": " + format
    }
    
    var format: String {
        switch self {
        case .ppt:                return "ppt"
        case .word:               return "docx doc"
        case .pdf:                return "pdf"
        case .video:              return "mp4"
        case .audio:              return "mp3"
        case .photo:              return "png jpg"
        case .sharingCourseware:  return "alf"
        }
    }
}

fileprivate class FcrCloudDriveFileFormatCell: UITableViewCell,
                                               AgoraUIContentContainer {
    let iconImageView = UIImageView(frame: .zero)
    let titleLabel = UILabel(frame: .zero)
    let formatLabel = UILabel(frame: .zero)
    
    override init(style: UITableViewCell.CellStyle,
                  reuseIdentifier: String?) {
        super.init(style: style,
                   reuseIdentifier: reuseIdentifier)
        initViews()
        initViewFrame()
        updateViewProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initViews() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(formatLabel)
        
        titleLabel.font = UIFont.systemFont(ofSize: 9,
                                            weight: .bold)
        formatLabel.font = UIFont.systemFont(ofSize: 9)
    }
    
    func initViewFrame() {
        iconImageView.agora_mas_makeConstraints { make in
            make?.top.left().equalTo()(0)
            make?.width.height().equalTo()(30)
        }
        
        titleLabel.agora_mas_makeConstraints { make in
            make?.left.equalTo()(iconImageView.agora_mas_right)?.offset()(10)
            make?.height.equalTo()(9)
            make?.right.equalTo()(0)
            make?.centerY.equalTo()(iconImageView.agora_mas_centerY)?.offset()(-5)
        }
        
        formatLabel.agora_mas_makeConstraints { make in
            make?.left.equalTo()(iconImageView.agora_mas_right)?.offset()(10)
            make?.height.equalTo()(9)
            make?.right.equalTo()(0)
            make?.centerY.equalTo()(iconImageView.agora_mas_centerY)?.offset()(5)
        }
    }
    
    func updateViewProperties() {
        
    }
}

class FcrCloudDriveFileFormatView: UIView,
                                   AgoraUIContentContainer,
                                   UITableViewDataSource,
                                   UITableViewDelegate {
    let titleLabel = UILabel(frame: .zero)
    let contentView = UIView(frame: .zero)
    let tableView = UITableView(frame: .zero)
    let closeButton = UIButton(frame: .zero)
    fileprivate let dataSource = FileType.allCases
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initViews()
        initViewFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initViews() {
        addSubview(contentView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(closeButton)
        contentView.addSubview(tableView)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(FcrCloudDriveFileFormatCell.self,
                           forCellReuseIdentifier: "FcrCloudDriveFileFormatCell")
        tableView.separatorStyle = .none
        tableView.rowHeight = 40
        
        tableView.reloadData()
    }
    
    func initViewFrame() {
        contentView.agora_mas_makeConstraints { make in
            make?.width.equalTo()(375)
            make?.top.equalTo()(0)
            make?.bottom.equalTo()(0)
            make?.right.equalTo()(0)
        }
        
        titleLabel.agora_mas_makeConstraints { make in
            make?.left.equalTo()(25)
            make?.top.equalTo()(20)
            make?.height.equalTo()(17)
            make?.right.equalTo()(-100)
        }
        
        closeButton.agora_mas_makeConstraints { make in
            let right = UIScreen.agora_safe_area_right + 10
            
            make?.right.equalTo()(-right)
            make?.top.equalTo()(10)
            make?.width.height().equalTo()(20)
        }
        
        tableView.agora_mas_makeConstraints { make in
            make?.top.equalTo()(titleLabel.agora_mas_bottom)?.offset()(28)
            make?.left.equalTo()(20)
            make?.right.equalTo()(0)
            make?.bottom.equalTo()(-24)
        }
    }
    
    func updateViewProperties() {
        contentView.backgroundColor = .white
        
        titleLabel.text = "文件格式要是"
        
        closeButton.setImage(UIImage.widgets_image("cloud_close"),
                             for: .normal)
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FcrCloudDriveFileFormatCell") as! FcrCloudDriveFileFormatCell
        let item = dataSource[indexPath.row]
        
        cell.iconImageView.image = item.image
        cell.titleLabel.text = item.title
        cell.formatLabel.text = item.formatText
        
        return cell
    }
}
