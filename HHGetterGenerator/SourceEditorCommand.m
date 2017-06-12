//
//  SourceEditorCommand.m
//  HHGetterGenerator
//
//  Created by 黑花白花 on 2017/6/10.
//  Copyright © 2017年 黑花白花. All rights reserved.
//

#import "SourceEditorCommand.h"

@implementation SourceEditorCommand

- (void)performCommandWithInvocation:(XCSourceEditorCommandInvocation *)invocation completionHandler:(void (^)(NSError * _Nullable nilOrError))completionHandler
{
    
    XCSourceTextRange *selection = invocation.buffer.selections.firstObject;
    if (selection) {
     
        NSString *endText = @"@end";
        NSInteger endTextIndex = 0;
        
        NSMutableArray *allLines = invocation.buffer.lines;
        for (NSInteger lineIndex = selection.start.line; lineIndex <= selection.end.line; lineIndex++) {
            
            NSString *lineText = allLines[lineIndex];
            NSString *propertyDescription = [lineText stringByReplacingOccurrencesOfString:@" " withString:@""];
            if (isObjectProperty(propertyDescription)) {
                
                if (endTextIndex == 0) {
                    
                    for (NSInteger index = allLines.count - 1; index > 10; index--) {
                        if ([allLines[index] hasPrefix:endText]) {
                            endTextIndex = index; break;
                        }
                    }
                }
                
                NSString *className = parseClassName(propertyDescription);
                NSString *propertyName = parsePropertyName(propertyDescription);
                NSArray *getterDescription = generateGetterDescription(className, propertyName);
                for (NSInteger index = 0; index < getterDescription.count; index++) {
                    [allLines addObject:getterDescription[index]];
                }
                [allLines addObject:@"\n"];
            }
        }
        
        if (endTextIndex > 0) {
            
            [allLines removeObjectAtIndex:endTextIndex];
            [allLines addObject:endText];
        }
    }
    
    completionHandler(nil);
}

#pragma mark - Utils

static inline BOOL isObjectProperty(NSString *lineText) {
    return [lineText hasPrefix:@"@property"] && ![lineText containsString:@"assign"];
}

static inline NSString *parseClassName(NSString *lineText) {
    
    NSArray *propertyDescription = [lineText componentsSeparatedByString:@")"];
    propertyDescription = [[propertyDescription lastObject] componentsSeparatedByString:@"*"];
    return [propertyDescription firstObject];
}

static inline NSString *parsePropertyName(NSString *lineText) {
    
    NSString *propertyName = [[lineText componentsSeparatedByString:@"*"] lastObject];
    propertyName = [propertyName stringByReplacingOccurrencesOfString:@";" withString:@""];
    propertyName = [propertyName stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return propertyName;
}

static inline NSArray *generateGetterDescription(NSString *className, NSString *propertyName) {
    
#define ReturnGetter(clsName) if ([className isEqualToString:[NSString stringWithUTF8String:#clsName]]) return clsName##Getter(propertyName);
    
    ReturnGetter(UIView)
    ReturnGetter(UILabel)
    ReturnGetter(UIButton)
    ReturnGetter(UITextView)
    ReturnGetter(UITextField)
    ReturnGetter(UIImageView)
    ReturnGetter(UITableView)
    ReturnGetter(UICollectionView)
    
//    ReturnGetter(NewClassName)
    
    return nil;
}

#pragma mark - Getter

#define AddLine(FORMAT, ...) [getter addObject:[NSString stringWithFormat:FORMAT, ##__VA_ARGS__]];

#define GetterBeginWithoutInit NSMutableArray *getter = [NSMutableArray array];\
                               AddLine(@"- (%@ *)%@ {",className, propertyName)\
                               AddLine(@"   if (!_%@) {",propertyName)\

#define GetterBegin GetterBeginWithoutInit\
                    AddLine(@"       _%@ = [%@ new];",propertyName, className)

#define GetterEnd   AddLine(@"   }")\
                    AddLine(@"   return _%@;",propertyName)\
                    AddLine(@"}" )\
                    return getter;

#define AddBackgroundColorLine AddLine(@"       _%@.backgroundColor = [UIColor <#Color#>];",propertyName)

static inline NSArray *UIViewGetter(NSString *propertyName) {
    
    NSString *className = @"UIView";
    GetterBegin
    AddBackgroundColorLine
    GetterEnd
}

static inline NSArray *UILabelGetter(NSString *propertyName) {
    
    NSString *className = @"UILabel";
    GetterBegin
    
    AddLine(@"       _%@.font = [UIFont systemFontOfSize:<#(CGFloat)#>];",propertyName);
    AddLine(@"       _%@.textColor = <#Color#>;",propertyName)
    AddBackgroundColorLine
    
    GetterEnd
}

static inline NSArray *UIButtonGetter(NSString *propertyName) {
    
    NSString *className = @"UIButton";
    GetterBeginWithoutInit
    
    AddLine(@"       _%@ = [UIButton buttonWithType:UIButtonTypeCustom];",propertyName)
    AddLine(@"       _%@.titleLabel.font = [UIFont systemFontOfSize:<#(CGFloat)#>];",propertyName)
    AddLine(@"       [_%@ setTitle:<#Title#> forState:UIControlStateNormal];",propertyName)
    AddLine(@"       [_%@ setTitleColor:<#Color#> forState:UIControlStateNormal];",propertyName);
    
    GetterEnd
}

static inline NSArray *UITextViewGetter(NSString *propertyName) {
    
    NSString *className = @"UITextView";
    GetterBegin
    
    AddLine(@"       _%@.font = [UIFont systemFontOfSize:<#(CGFloat)#>];",propertyName);
    AddLine(@"       _%@.textColor = <#Color#>;",propertyName)
    
    GetterEnd
}

static inline NSArray *UITextFieldGetter(NSString *propertyName) {
    
    NSString *className = @"UITextField";
    GetterBegin
    
    AddLine(@"       _%@.borderStyle = <#UITextBorderStyle#>;",propertyName)
    AddLine(@"       _%@.returnKeyType = <#UIReturnKeyType#>;",propertyName)
    AddLine(@"       _%@.secureTextEntry = <#BOOL#>;",propertyName)
    AddLine(@"       _%@.clearButtonMode = UITextFieldViewModeWhileEditing;",propertyName)
    AddLine(@"       _%@.keyboardAppearance = UIKeyboardAppearanceDefault;",propertyName)
    
    GetterEnd
}

static inline NSArray *UIImageViewGetter(NSString *propertyName) {
    
    NSString *className = @"UIImageView";
    GetterBegin
    
    AddLine(@"       _%@.contentMode = UIViewContentModeScaleAspectFit;", propertyName)
    AddLine(@"       _%@.image = [UIImage imageNamed:<#(nonnull NSString *)#>];", propertyName)
    
    GetterEnd
}

static inline NSArray *UITableViewGetter(NSString *propertyName) {
    
    NSString *className = @"UITableView";
    GetterBeginWithoutInit
    
    AddLine(@"       _%@ = [[UITableView alloc] initWithFrame:<#(CGRect)#> style:<#(UITableViewStyle)#>]",propertyName)
    AddBackgroundColorLine
    
    GetterEnd
}

static inline NSArray *UICollectionViewGetter(NSString *propertyName) {
    
    NSString *className = @"UICollectionView";
    GetterBeginWithoutInit
    
    AddLine(@"        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];")
    AddLine(@"        flowLayout.itemSize = CGSizeMake(<#CGFloat width#>, <#CGFloat height#>);")
    AddLine(@"        flowLayout.minimumLineSpacing = <#Spacing#>;")
    AddLine(@"        flowLayout.minimumInteritemSpacing = <#Spacing#>;")
    AddLine(@"       _%@ = [[UICollectionView alloc] initWithFrame:<#CGRect#> collectionViewLayout:flowLayout];",propertyName)
    AddBackgroundColorLine
    
    GetterEnd
}

static inline NSArray *NewClassNameGetter(NSString *propertyName) { return nil; }

@end
