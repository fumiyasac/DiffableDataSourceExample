# [ING] - DiffableDataSourceを利用した実装例とその他Combineを活用した実装例

UICollectionViewCompositionalLayoutを利用した「Pinterestの様なWaterFallLayout」と「Scrollが最下部に達した際に次ページが追加されるような実装とRefreshControl部分」をCombineを利用した実装で実現したUI実装サンプルになります。

### 1. このサンプルについて

__【サンプル画面のデザイン】__

![サンプル図その1](https://github.com/fumiyasac/DiffableDataSourceExample/blob/master/images/sample_thumbnail1.jpg)

![サンプル図その2](https://github.com/fumiyasac/DiffableDataSourceExample/blob/master/images/sample_thumbnail2.jpg)

__【利用しているUIライブラリ】__

+ [PTCardTabBar](https://github.com/hussc/PTCardTabBar) : DesignicなTabBarを実現するライブラリ
+ [AlamofireImage](https://github.com/Alamofire/AlamofireImage) : 画像キャッシュ用ライブラリ

### 2. 事前準備と検証用Mockサーバーについて

本サンプルにおいてAPI通信を利用してデータの取得を行う機構を用意するにあたり、ローカル環境下でのAPI通信用のモックサーバー構築に[json-server](https://github.com/typicode/json-server)を利用しました。node.jsを利用した経験があるならば、すぐに導入できるかと思います。具体的な使い方は[こちら](https://blog.eleven-labs.com/en/json-server/)を参照して頂ければと思います。

利用する際には下記のような手順でお願いします。

__必要なパッケージのインストール:__

```
$ cd mock_server
$ npm install
```

__API通信用Mockサーバー起動:__

```
$ node index.js
```

1. 実機検証はできません。
2. 事前にnode.jsのインストールが必要になります。

### 3. Pinterestの様なWaterFallLayoutを実現するための実装

UICollectionViewCompositionalLayoutとJSONデータのレスポンス内の写真の縦横比率情報を利用した、Pinterestの様なWaterFallLayoutの実装をしています。個人的な所管としましては、従来のUICollectionViewLayoutのクラスを継承してLayoutAttributesの値を加工する方法よりも直感的ではないかとも思います。

+ [CompositionalTwoColumnWaterfall.swift](https://gist.github.com/breeno/f16330c5ef06075b0fc476c65d9b00d8)

__実装箇所の抜粋:__

```swift
private func applyForWaterFallLayoutSection() -> NSCollectionLayoutSection {

    // MEMO: 表示するアイテムが存在する場合は各セルの高さの適用とそれに基くUICollectionView全体の高さを計算する

    // Model内で持っているheightの値を適用することでWaterFallLayoutの様な見た目を実現する
    var leadingGroupHeight: CGFloat = 0.0
    var trailingGroupHeight: CGFloat = 0.0
    var leadingGroupItems: [NSCollectionLayoutItem] = []
    var trailingGroupItems: [NSCollectionLayoutItem] = []

    let photos = snapshot.itemIdentifiers(inSection: .WaterFallLayout)
    let totalHeight = photos.reduce(CGFloat(0)) { $0 + $1.height }
    let columnHeight = CGFloat(totalHeight / 2.0)

    var runningHeight = CGFloat(0.0)

    // 1. Itemのサイズ設定
    for index in 0..<snapshot.numberOfItems {

        let photo = photos[index]
        let isLeading = runningHeight < columnHeight
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(photo.height))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)

        runningHeight += photo.height

        if isLeading {
            leadingGroupItems.append(item)
            leadingGroupHeight += photo.height
        } else {
            trailingGroupItems.append(item)
            trailingGroupHeight += photo.height
        }
    }

    // 2. Groupのサイズ設定
    let leadingGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(leadingGroupHeight))
    let leadingGroup = NSCollectionLayoutGroup.vertical(layoutSize: leadingGroupSize, subitems: leadingGroupItems)

    let trailingGroupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.5), heightDimension: .absolute(trailingGroupHeight))
    let trailingGroup = NSCollectionLayoutGroup.vertical(layoutSize: trailingGroupSize, subitems: trailingGroupItems)

    let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0), heightDimension: .absolute(max(leadingGroupHeight, trailingGroupHeight)))
    let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [leadingGroup, trailingGroup])

    // 3. Sectionのサイズ設定
    let section = NSCollectionLayoutSection(group: group)

    return section
}
```

### 4. Scrollが最下部に達した際に次ページが追加されるような実装とRefreshControl部分

本サンプルにおけるAPIリクエストからデータを反映させる部分については基本的に「Combine + MVVM』の構成で実装をしています。UIScrollViewDelegateを利用してコンテンツ表示位置が最下部まで到達した時をトリガーとして、ViewModel側に定義した次のページ表示用のAPIリクエストを実行している点がポイントになります。

__実装箇所の抜粋:__

```swift
final class MainViewController: UIViewController {

    ・・・（途中省略）・・・

    // ViewModelのOutputとこのViewControllerでのUIに関する処理をバインドする
    private func bindToViewModelOutputs() {

        // MEMO: APIへのリクエスト状態に合わせたUI側の表示におけるハンドリングを実行する
        viewModel.outputs.apiRequestStatus
            .subscribe(on: RunLoop.main)
            .sink(
                receiveValue: { [weak self] status in

                    guard let self = self else { return }
                    switch status {
                    case .requesting:
                        self.mainRefrashControl.beginRefreshing()
                    case .requestFailure:
                        // MEMO: 通信失敗時はアラート表示 & RefreshControlの状態変更
                        self.mainRefrashControl.endRefreshing()
                        self.showAlertWith(completionHandler: nil)
                    default:
                        self.mainRefrashControl.endRefreshing()
                    }
                }
            )
            .store(in: &cancellables)

        // MEMO: APIへのリクエスト状態に合わせたUI側の表示におけるハンドリングを実行する
        viewModel.outputs.photos
            .subscribe(on: RunLoop.main)
            .sink(
                receiveValue: { [weak self] photos in

                    guard let self = self else { return }
                    // MEMO: ID(Identifier)が重複する場合における衝突の回避をする
                    let beforePhoto = self.snapshot.itemIdentifiers(inSection: .WaterFallLayout)
                    self.snapshot.deleteItems(beforePhoto)
                    self.snapshot.appendItems(photos, toSection: .WaterFallLayout)
                    self.dataSource.apply(self.snapshot, animatingDifferences: false)
                }
            )
            .store(in: &cancellables)
    }

    ・・・（途中省略）・・・
}

・・・（途中省略）・・・

extension MainViewController: UIScrollViewDelegate {

    // MEMO: NSCollectionLayoutSectionのScroll(section.orthogonalScrollingBehavior)ではUIScrollViewDelegateは呼ばれない
    func scrollViewDidScroll(_ scrollView: UIScrollView) {

        // MEMO: UIRefreshControl表示時は以降の処理を行わない(※APIリクエストの状態とRefreshControlの状態を連動させている点がポイント)
        if mainRefrashControl.isRefreshing {
            return
        }

        // MEMO: UIScrollViewが一番下の状態に達した時にAPIリクエストを実行する
        if scrollView.contentOffset.y + scrollView.frame.size.height > scrollView.contentSize.height {
            viewModel.inputs.fetchPhotoTrigger.send()
        }
    }
}
```

このサンプルでは、ViewControllerからのViewModelへのアクセス時に入力(Input)・出力(Output)をわかりやすくする意図も込めて「Kickstarter-iOS」で採用しているViewModelの構成に近しい形としています。

+ [Introducing ViewModel Inputs/Outputs: a modern approach to MVVM architecture](https://tech.mercari.com/entry/2019/06/12/120000)
+ [Kickstarter-iOSのViewModelの作り方がウマかった](https://qiita.com/muukii/items/045b12405f7acff1a9fd)

