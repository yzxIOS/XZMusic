//
//  XZAddPraiseViewController.m
//  XZMusic
//
//  Created by xiazer on 15/1/3.
//  Copyright (c) 2015年 xiazer. All rights reserved.
//

#import "XZAddPraiseViewController.h"
#import "XZMusicCoreDataCenter.h"
#import "XZSongCell.h"

@interface XZAddPraiseViewController ()

@end

@implementation XZAddPraiseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    [self setTitleViewWithString:@"点赞歌曲"];
    
    [self initData];
}

- (void)initData
{
    self.tableData = (NSMutableArray *)[[XZMusicCoreDataCenter shareInstance] fetchAllMusicByLoved];
    [self setTitleViewWithString:[NSString stringWithFormat:@"点赞歌曲(%ld)",(long)self.tableData.count]];

    [self.tableList reloadData];
}

#pragma mark - UITableViewDataSource
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.tableData.count;
}
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentify = @"cell";
    XZSongCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentify];
    if (!cell) {
        cell = [[XZSongCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentify];
        cell.cellType = CellTypeForNormal;
    }
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    XZMusicInfo *singerInfoMode = (XZMusicInfo *)[self.tableData objectAtIndex:indexPath.row];
    
    [cell configCell:singerInfoMode];
    
    return cell;
}

#pragma mark - UITableDelegate
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    XZMusicInfo *musicInfo = [self.tableData objectAtIndex:indexPath.row];
    
    XZMusicPlayViewController *playVC = [XZMusicPlayViewController shareInstance];
    if ([[XZGlobalManager shareInstance].playMusicId isEqualToString:musicInfo.musicId] && [XZGlobalManager shareInstance].isPlaying) {
        [self.navigationController pushViewController:playVC animated:YES];
    } else {
        [playVC playingMusicWithExistSong:musicInfo];
        [XZGlobalManager shareInstance].isPlaying = YES;
        // 设置全局播放数据
        [XZGlobalManager shareInstance].musicArr = (NSMutableArray *)[[XZMusicCoreDataCenter shareInstance] fetchAllMusicByLoved];
        [XZGlobalManager shareInstance].playMusicId = [NSString stringWithFormat:@"%@",musicInfo.musicId];
        [XZGlobalManager shareInstance].playIndex = indexPath.row;
        
        [self.navigationController pushViewController:playVC animated:YES];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
