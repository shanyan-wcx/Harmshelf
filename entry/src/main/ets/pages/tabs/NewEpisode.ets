import { Episode } from '../../api/Interface'

function htmlToText(html: string): string {
  let text = html.replace(/<br\s*\/?>/gi, '\n');
  text = text.replace(/<[^>]+>/g, '');
  return text;
}

function formatDate(input: string): string {
  const dateRegex = /(\d{2}) (\w{3}) (\d{4})/;
  const match = input.match(dateRegex);
  if (match) {
    const day = match[1];
    const monthStr = match[2];
    const year = match[3];
    let month = '';
    switch (monthStr) {
      case 'Jan':
        month = '01';
        break;
      case 'Feb':
        month = '02';
        break;
      case 'Mar':
        month = '03';
        break;
      case 'Apr':
        month = '04';
        break;
      case 'May':
        month = '05';
        break;
      case 'Jun':
        month = '06';
        break;
      case 'Jul':
        month = '07';
        break;
      case 'Aug':
        month = '08';
        break;
      case 'Sep':
        month = '09';
        break;
      case 'Oct':
        month = '10';
        break;
      case 'Nov':
        month = '11';
        break;
      case 'Dec':
        month = '12';
        break;
      default:
        return 'Invalid date';
    }
    return `${year}-${month}-${day}`;
  }
  return 'Invalid date';
}

@Component
export default struct newEpisode {
  @Consume sidebarShow: boolean
  @Consume recentEpisodes: Episode[]
  @Consume server: string
  @Consume apitoken: string

  build() {
    List() {
      ListItem() {
        Text("最新剧集")
          .fontSize(24)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .margin({ top: 20, left: 20 })
      }

      ForEach(this.recentEpisodes, (episode: Episode, index) => {
        ListItem() {
          Column() {
            Row() {
              Image(this.server + `/api/items/${episode.libraryItemId}/cover?format=jpeg&width=1024` +
                `&token=${this.apitoken}`)
                .alt($rawfile('nocover.jpg'))
                .width(60)
                .height(60)
                .borderRadius(10)
              Column() {
                Text(episode.audioFile!.metaTags.tagAlbum)
                  .fontSize(20)
                  .fontColor(Color.White)
                  .maxLines(1)
                  .margin({ top: 5 })
                Text(formatDate(episode.pubDate))
                  .fontSize(18)
                  .fontColor(Color.Gray)
                  .maxLines(1)
                  .margin({ top: 5 })
              }
              .height(60)
              .margin({ left: 10 })
              .justifyContent(FlexAlign.Start)
              .alignItems(HorizontalAlign.Start)
            }
            .margin({ top: 20 })

            Text(episode.title)
              .fontSize(20)
              .fontColor(Color.White)
              .maxLines(1)
              .margin({ top: 10 })
            Text(htmlToText(episode.description))
              .fontSize(18)
              .fontColor(Color.Gray)
              .margin({ top: 10 })
              .width('100%')
              .padding({ left: 10, right: 10 })
              .maxLines(5)
            Button() {
              Text("播放")
                .fontSize(20)
                .fontColor(Color.White)
            }
            .width(80)
            .height(40)
            .margin({ top: 10, left: 5 })
            .backgroundColor(Color.Green)

            Divider()
              .width('100%')
              .height(1)
              .color(Color.Gray)
              .margin({ top: 20 })
          }
          .width('100%')
          .height('auto')
          .padding({ left: 20, right: 20 })
          .alignItems(HorizontalAlign.Start)
        }
      })
    }
    .width('100%')
    .height('100%')
    .scrollBar(BarState.Off)
    .edgeEffect(EdgeEffect.Fade)
  }
}