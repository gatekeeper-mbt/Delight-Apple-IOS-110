//
//  DateTimePicker.swift
//  DateTimePicker
//
//  Created by Huong Do on 9/16/16.
//  Copyright © 2016 ichigo. All rights reserved.
//

import UIKit


@objc public class DateTimePicker: UIView {
    var contentHeight: CGFloat = 310
    
    // public vars
    public var backgroundViewColor: UIColor? = .clear {
        didSet {
            shadowView.backgroundColor = backgroundViewColor
        }
    }
    
    public var highlightColor = UIColor(red: 0/255.0, green: 199.0/255.0, blue: 194.0/255.0, alpha: 1) {
        didSet {
            doneButton.setTitleColor(highlightColor, for: .normal)
            colonLabel1.textColor = highlightColor
            colonLabel2.textColor = highlightColor
        }
    }
    
    public var darkColor = UIColor(red: 0, green: 22.0/255.0, blue: 39.0/255.0, alpha: 1) {
        didSet {
            cancelButton.setTitleColor(darkColor.withAlphaComponent(0.5), for: .normal)
            separatorTopView.backgroundColor = darkColor.withAlphaComponent(0.2)
            separatorBottomView.backgroundColor = darkColor.withAlphaComponent(0.2)
        }
    }
    
    public var daysBackgroundColor = UIColor(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, alpha: 1)
    
    var didLayoutAtOnce = false
    public override func layoutSubviews() {
        super.layoutSubviews()
        // For the first time view will be layouted manually before show
        // For next times we need relayout it because of screen rotation etc.
        if !didLayoutAtOnce {
            didLayoutAtOnce = true
        } else {
            self.configureView()
        }
    }
    
    var currentTime = TimerMem()
    var returnTimer = 0
    
    public var setTimer = 1800 {
        didSet {
            resetTime()
        }
    }
    
    public var cancelButtonTitle = NSLocalizedString("alertdialog_cancel", comment: "") {
        didSet {
            cancelButton.setTitle(cancelButtonTitle, for: .normal)
            let size = cancelButton.sizeThatFits(CGSize(width: 0, height: 44.0)).width + 20.0
            cancelButton.frame = CGRect(x: 0, y: 0, width: size, height: 44)
        }
    }
    
    public var doneButtonTitle = NSLocalizedString("alertdialog_ok", comment: "") {
        didSet {
            doneButton.setTitle(doneButtonTitle, for: .normal)
            let size = doneButton.sizeThatFits(CGSize(width: 0, height: 44.0)).width + 20.0
            doneButton.frame = CGRect(x: contentView.frame.width - size, y: 0, width: size, height: 44)
        }
    }
    
    public var completionHandler: ((Int)->Void)?
    
    // private vars
    internal var hourTableView: UITableView!
    internal var minuteTableView: UITableView!
    internal var secondTableView: UITableView!
    
    private var shadowView: UIView!
    private var contentView: UIView!
    private var doneButton: UIButton!
    private var cancelButton: UIButton!
    private var colonLabel1: UILabel!
    private var colonLabel2: UILabel!
    private var hourLabel: UILabel!
    private var minLabel: UILabel!
    private var secLabel: UILabel!
    
    private var separatorTopView: UIView!
    private var separatorBottomView: UIView!
    
    internal var dates: [Date]! = []

    
    
    @objc open class func show() -> DateTimePicker {
        let dateTimePicker = DateTimePicker()
        
        dateTimePicker.configureView()
        UIApplication.shared.keyWindow?.addSubview(dateTimePicker)
        
        return dateTimePicker
    }
    
    private func configureView() {
        if self.contentView != nil {
            self.contentView.removeFromSuperview()
        }
        let screenSize = UIScreen.main.bounds.size
        self.frame = CGRect(x: 0,
                            y: 0,
                            width: screenSize.width,
                            height: screenSize.height)
        // shadow view
        shadowView = UIView(frame: CGRect(x: 0,
                                          y: 0,
                                          width: frame.width,
                                          height: frame.height))
        shadowView.backgroundColor = backgroundViewColor ?? UIColor.black.withAlphaComponent(0.3)
        shadowView.alpha = 1
        let shadowViewTap = UITapGestureRecognizer(target: self, action: #selector(DateTimePicker.dismissView(sender:)))
        shadowView.addGestureRecognizer(shadowViewTap)
        addSubview(shadowView)
        
        // content view
        contentView = UIView(frame: CGRect(x: 0,
                                           y: frame.height,
                                           width: frame.width,
                                           height: contentHeight))
        contentView.layer.shadowColor = UIColor(white: 0, alpha: 0.3).cgColor
        contentView.layer.shadowOffset = CGSize(width: 0, height: -2.0)
        contentView.layer.shadowRadius = 1.5
        contentView.layer.shadowOpacity = 0.5
        contentView.backgroundColor = .white
        contentView.isHidden = true
        addSubview(contentView)
        
        // title view
        let titleView = UIView(frame: CGRect(origin: CGPoint.zero,
                                             size: CGSize(width: contentView.frame.width, height: 44)))
        titleView.backgroundColor = .white
        contentView.addSubview(titleView)
        
        cancelButton = UIButton(type: .system)
        cancelButton.setTitle(cancelButtonTitle, for: .normal)
        cancelButton.setTitleColor(darkColor.withAlphaComponent(0.5), for: .normal)
        cancelButton.addTarget(self, action: #selector(DateTimePicker.dismissView(sender:)), for: .touchUpInside)
        cancelButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        let cancelSize = cancelButton.sizeThatFits(CGSize(width: 0, height: 44.0)).width + 20.0
        cancelButton.frame = CGRect(x: 0, y: 0, width: cancelSize, height: 44)
        titleView.addSubview(cancelButton)
        
        // done button
        doneButton = UIButton(type: .system)
        doneButton.setTitle(doneButtonTitle, for: .normal)
        doneButton.setTitleColor(highlightColor, for: .normal)
        doneButton.addTarget(self, action: #selector(DateTimePicker.dismissView(sender:)), for: .touchUpInside)
        doneButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        doneButton.isHidden = false
        let doneSize = doneButton.sizeThatFits(CGSize(width: 0, height: 44.0)).width + 20.0
        doneButton.frame = CGRect(x: contentView.frame.width - doneSize, y: 0, width: doneSize, height: 44)
        titleView.addSubview(doneButton)
        
        // if time picker format is 12 hour, we'll need an extra tableview for am/pm
        let extraSpace: CGFloat = 45
        let Yoffset: CGFloat = 10
        let RowHeight: CGFloat = 70
        let TableHeight:CGFloat = (RowHeight * 3) - 6
        let TableHWidth:CGFloat = 95

        // hour table view
        hourTableView = UITableView(frame: CGRect(x: contentView.frame.width / 2 - (TableHWidth + extraSpace),
                                                  y: titleView.frame.height + Yoffset,
                                                  width: TableHWidth,
                                                  height: TableHeight))
        hourTableView.rowHeight = RowHeight
        hourTableView.contentInset = UIEdgeInsetsMake(hourTableView.frame.height / 2, 0, hourTableView.frame.height / 2, 0)
        hourTableView.showsVerticalScrollIndicator = false
        hourTableView.separatorStyle = .none
        hourTableView.delegate = self
        hourTableView.dataSource = self
        hourTableView.isHidden = false
        contentView.addSubview(hourTableView)
        
        // minute table view
        minuteTableView = UITableView(frame: CGRect(x: contentView.frame.width / 2 - extraSpace,
                                                    y: titleView.frame.height + Yoffset,
                                                    width: TableHWidth,
                                                    height: TableHeight))
        minuteTableView.rowHeight = RowHeight
        minuteTableView.contentInset = UIEdgeInsetsMake(minuteTableView.frame.height / 2, 0, minuteTableView.frame.height / 2, 0)
        minuteTableView.showsVerticalScrollIndicator = false
        minuteTableView.separatorStyle = .none
        minuteTableView.delegate = self
        minuteTableView.dataSource = self
        minuteTableView.isHidden = false
        contentView.addSubview(minuteTableView)
        
        // second table view
        secondTableView = UITableView(frame: CGRect(x: contentView.frame.width / 2 + extraSpace,
                                                    y: titleView.frame.height + Yoffset,
                                                    width: TableHWidth,
                                                    height: TableHeight))
        secondTableView.rowHeight = RowHeight
        secondTableView.contentInset = UIEdgeInsetsMake(secondTableView.frame.height / 2, 0, secondTableView.frame.height / 2, 0)
        secondTableView.showsVerticalScrollIndicator = false
        secondTableView.separatorStyle = .none
        secondTableView.delegate = self
        secondTableView.dataSource = self
        secondTableView.isHidden = false
        contentView.addSubview(secondTableView)
        
        // colon
        colonLabel1 = UILabel(frame: CGRect(x: 0, y: 0, width: 10, height: 36))
        colonLabel1.center = CGPoint(x: contentView.frame.width / 2 - extraSpace,
                                    y: minuteTableView.frame.height / 2 + minuteTableView.frame.origin.y - 5)
        colonLabel1.text = ":"
        colonLabel1.font = UIFont.boldSystemFont(ofSize: 50)
        colonLabel1.textColor = highlightColor
        colonLabel1.textAlignment = .center
        colonLabel1.isHidden = false
        contentView.addSubview(colonLabel1)
        
        colonLabel2 = UILabel(frame: CGRect(x: 0, y: 0, width: 10, height: 36))
        colonLabel2.text = ":"
        colonLabel2.font = UIFont.boldSystemFont(ofSize: 50)
        colonLabel2.textColor = highlightColor
        colonLabel2.textAlignment = .center
        var colon2Center = colonLabel1.center
        colon2Center.x += 90
        colonLabel2.center = colon2Center
        colonLabel2.isHidden = false
        contentView.addSubview(colonLabel2)

        // time separators
        separatorTopView = UIView(frame: CGRect(x: 0, y: 0, width: 165 + extraSpace * 2, height: 1))
        separatorTopView.backgroundColor = darkColor.withAlphaComponent(0.2)
        separatorTopView.center = CGPoint(x: contentView.frame.width / 2, y: minuteTableView.frame.origin.y + RowHeight )
        separatorTopView.isHidden = false
        contentView.addSubview(separatorTopView)
        
        separatorBottomView = UIView(frame: CGRect(x: 0, y: 0, width: 165 + extraSpace * 2, height: 1))
        separatorBottomView.backgroundColor = darkColor.withAlphaComponent(0.2)
        separatorBottomView.center = CGPoint(x: contentView.frame.width / 2, y: separatorTopView.frame.origin.y + RowHeight )
        separatorBottomView.isHidden = false
        contentView.addSubview(separatorBottomView)

        //
        hourLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 36))
        hourLabel.center = CGPoint(x: hourTableView.frame.origin.x + (hourTableView.frame.width / 2),
                                     y: TableHeight + 70)
        hourLabel.text = NSLocalizedString("time_hour", comment: "")
        hourLabel.font = UIFont.boldSystemFont(ofSize: 24)
        hourLabel.textColor = highlightColor
        hourLabel.textAlignment = .center
        hourLabel.isHidden = false
        contentView.addSubview(hourLabel)

        minLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 36))
        minLabel.center = CGPoint(x: minuteTableView.frame.origin.x + (minuteTableView.frame.width / 2),
                                   y: TableHeight + 70)
        minLabel.text = NSLocalizedString("time_min", comment: "")
        minLabel.font = UIFont.boldSystemFont(ofSize: 24)
        minLabel.textColor = highlightColor
        minLabel.textAlignment = .center
        minLabel.isHidden = false
        contentView.addSubview(minLabel)
        
        secLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 100, height: 36))
        secLabel.center = CGPoint(x: secondTableView.frame.origin.x + (secondTableView.frame.width / 2),
                                   y: TableHeight + 70)
        secLabel.text = NSLocalizedString("time_sec", comment: "")
        secLabel.font = UIFont.boldSystemFont(ofSize: 24)
        secLabel.textColor = highlightColor
        secLabel.textAlignment = .center
        secLabel.isHidden = false
        contentView.addSubview(secLabel)
        
        contentView.isHidden = false
        
        resetTime()
        
        // animate to show contentView
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.4, options: .curveEaseIn, animations: {
            self.contentView.frame = CGRect(x: 0,
                                            y: self.frame.height - self.contentHeight,
                                            width: self.frame.width,
                                            height: self.contentHeight)
        }, completion: nil)
    }
    
    func resetTime() {
        
        var hour = 0
        var minute = 0
        var second = 0

        var time = setTimer
        //var hour = 0
        if time >= 3600{
            hour = Int(time / 3600)
            time = time - (hour * 3600)
        }
        
        //var minute = 0;
        if time >= 60 {
            minute = Int(time / 60)
            time = time - (minute * 60)
        }
        
        second = Int(time)
        
        currentTime.hour = hour
        currentTime.minute = minute
        currentTime.second = second
        returnTimer = (currentTime.hour * 3600) + (currentTime.minute * 60) + currentTime.second

        var expectedRow = hour == 0 ? 26 :  hour + 13
        hourTableView.selectRow(at: IndexPath(row: expectedRow, section: 0), animated: true, scrollPosition: .middle)
        
        expectedRow = minute == 0 ? 120 : minute + 60 // workaround for issue when minute = 0
        minuteTableView.selectRow(at: IndexPath(row: expectedRow, section: 0), animated: true, scrollPosition: .middle)
        
        expectedRow = second == 0 ? 120 : second + 60 // workaround for issue when second = 0
        secondTableView.selectRow(at: IndexPath(row: expectedRow, section: 0), animated: true, scrollPosition: .middle)
    }
    
    public func dismissView(sender: UIButton?=nil) {
        UIView.animate(withDuration: 0.3, animations: {
            // animate to show contentView
            self.contentView.frame = CGRect(x: 0,
                                            y: self.frame.height,
                                            width: self.frame.width,
                                            height: self.contentHeight)
        }) { (completed) in
            if sender == self.doneButton {
                self.completionHandler?(self.returnTimer)
            }
            self.removeFromSuperview()
        }
    }
}

extension DateTimePicker: UITableViewDataSource, UITableViewDelegate {
    public func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == hourTableView {
            // need triple of origin storage to scroll infinitely
            return 13 * 3
        }
        // need triple of origin storage to scroll infinitely
        return 60 * 3
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "timeCell") ?? UITableViewCell(style: .default, reuseIdentifier: "timeCell")
        
        cell.selectedBackgroundView = UIView()
        cell.textLabel?.textAlignment = tableView == hourTableView ? .right : .left
        cell.textLabel?.font = UIFont.boldSystemFont(ofSize: 50)
        cell.textLabel?.textColor = darkColor.withAlphaComponent(0.4)
        cell.textLabel?.highlightedTextColor = highlightColor
        // add module operation to set value same
        if tableView == minuteTableView || tableView == secondTableView {
            cell.textLabel?.text = String(format: "%02i", indexPath.row % 60)
        } else {
            cell.textLabel?.text = String(format: "%02i", (indexPath.row % 13))
        }

        return cell
    }
    
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.selectRow(at: indexPath, animated: true, scrollPosition: .middle)
        
        if tableView == hourTableView {
            currentTime.hour = Int(indexPath.row - 13) % 13
        } else if tableView == minuteTableView {
            currentTime.minute = Int(indexPath.row - 60) % 60
        } else if tableView == secondTableView {
            currentTime.second = Int(indexPath.row - 60) % 60
        }

        returnTimer = (currentTime.hour * 3600) + (currentTime.minute * 60) + currentTime.second
    }
    
    // for infinite scrolling, use modulo operation.
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let totalHeight = scrollView.contentSize.height
        let visibleHeight = totalHeight / 3.0
        if scrollView.contentOffset.y < visibleHeight || scrollView.contentOffset.y > visibleHeight + visibleHeight {
            let positionValueLoss = scrollView.contentOffset.y - CGFloat(Int(scrollView.contentOffset.y))
            let heightValueLoss = visibleHeight - CGFloat(Int(visibleHeight))
            let modifiedPotisionY = CGFloat(Int( scrollView.contentOffset.y ) % Int( visibleHeight ) + Int( visibleHeight )) - positionValueLoss - heightValueLoss
            scrollView.contentOffset.y = modifiedPotisionY
        }
    }
}

extension DateTimePicker: UICollectionViewDataSource, UICollectionViewDelegate {
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dates.count
    }
    
    public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "dateCell", for: indexPath) as! DateCollectionViewCell
        
        let date = dates[indexPath.item]
        cell.populateItem(date: date, highlightColor: highlightColor, darkColor: darkColor)
        
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        //workaround to center to every cell including ones near margins
        if let cell = collectionView.cellForItem(at: indexPath) {
            let offset = CGPoint(x: cell.center.x - collectionView.frame.width / 2, y: 0)
            collectionView.setContentOffset(offset, animated: true)
        }
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        alignScrollView(scrollView)
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            alignScrollView(scrollView)
        }
    }
    
    func alignScrollView(_ scrollView: UIScrollView) {
        if let tableView = scrollView as? UITableView {
            let relativeOffset = CGPoint(x: 0, y: tableView.contentOffset.y + tableView.contentInset.top )
            // change row from var to let.
            let row = round(relativeOffset.y / tableView.rowHeight)

            tableView.selectRow(at: IndexPath(row: Int(row), section: 0), animated: true, scrollPosition: .middle)
            if tableView == hourTableView {
                currentTime.hour = Int(row - 13) % 13
            } else if tableView == minuteTableView {
                currentTime.minute = Int(row - 60) % 60
            } else if tableView == secondTableView {
                currentTime.second = Int(row - 60) % 60
            }

            returnTimer = (currentTime.hour * 3600) + (currentTime.minute * 60) + currentTime.second
        }
    }
}

struct TimerMem {
    var hour:Int!
    var minute:Int!
    var second:Int!
}
